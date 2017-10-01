from __future__ import print_function

import json
import logging
import os

import salt.config
import salt.utils.locales
from google.auth.transport.urllib3 import AuthorizedHttp
from google.oauth2.credentials import Credentials
from salt.ext.six.moves.urllib.parse import urlparse


# todo add recurse

def managed(name,
            source=None,
            source_hash='',
            source_hash_name=None,
            user=None,
            group=None,
            mode=None,
            template=None,
            makedirs=False,
            dir_mode=None,
            context=None,
            replace=True,
            defaults=None,
            backup='',
            show_changes=True,
            create=True,
            contents=None,
            tmp_ext='',
            contents_pillar=None,
            contents_grains=None,
            contents_newline=True,
            contents_delimiter=':',
            encoding=None,
            encoding_errors='strict',
            allow_empty=True,
            follow_symlinks=True,
            check_cmd=None,
            skip_verify=False,
            win_owner=None,
            win_perms=None,
            win_deny_perms=None,
            win_inheritance=True,
            **kwargs):
    '''
    State that extends file.managed with new source scheme (`gdrive://`)
    If other than `gdrive://` scheme is used, execution is delegated to `file.managed` state

    If the specified `source` path is ambiguous (on gdrive you can store multiple folders with same name)
    then the returned result is undefined (will fetch any of ambiguous folders/files)
    In order to use this state you must pre-authorize file_ext in your google drive using file_ext_authorize

    This extensions requires (pip):
     - google-auth
    Also set pillar_opts: True in master config file
    '''

    def delegate_to_file_managed(source, contents):
        return __states__['file.managed'](name, source, source_hash, source_hash_name, user, group, mode, template,
                                          makedirs, dir_mode, context, replace, defaults, backup, show_changes, create,
                                          contents, tmp_ext, contents_pillar, contents_grains, contents_newline,
                                          contents_delimiter, encoding, encoding_errors, allow_empty, follow_symlinks,
                                          check_cmd, skip_verify,
                                          win_owner, win_perms, win_deny_perms, win_inheritance, **kwargs)

    if not source:
        return delegate_to_file_managed(source, contents)
    source = salt.utils.locales.sdecode(source)
    if urlparse(source).scheme != 'gdrive':
        return delegate_to_file_managed(source, contents)

    log = logging.getLogger(__name__)
    source = urlparse(source)
    config = __salt__['config.get']('google_api')
    token_url = config['token_url']
    client_id = config['client_id']
    client_secret = config['client_secret']
    token = __salt__['pillar.get']("gdrive")
    log.debug("Token retrieved: {}".format(token))

    credentials = Credentials(token[u'access_token'], refresh_token=token[u'refresh_token'], token_uri=token_url,
                              client_id=client_id, client_secret=client_secret)
    authorized_http = AuthorizedHttp(credentials)

    path, file_name = os.path.split(source.netloc + source.path)
    parts = path.split(os.sep)
    log.debug("Asserting path: {} and filename: {}".format(parts, file_name))

    def download_file(file_id):
        log.debug("Fetching file: {} (id={})".format(file_name, file_id))
        return authorized_http.request('GET', 'https://www.googleapis.com/drive/v3/files/{}?alt=media'.format(file_id)).data

    def fetch_files(request_params):
        return json.loads(
            authorized_http.request('GET', 'https://www.googleapis.com/drive/v3/files', fields=request_params).data)

    def traverse_to_file(parent_id, idx):
        if idx > len(parts):
            return download_file(parent_id)

        next_name = parts[idx] if len(parts) > idx else file_name
        request_params = {
            'q': "'{}' in parents".format(parent_id)  # and mimeType = 'application/vnd.google-apps.folder'
        }
        json_response = fetch_files(request_params)
        r = [e for e in json_response['files'] if e['name'] == next_name]
        if len(r) > 0:
            # don't care if name occurred in other pages or already multiple times
            return traverse_to_file(r[0]['id'], idx + 1)
        elif 'nextPageToken' in json_response:
            while 'nextPageToken' in json_response:
                log.debug("Fetching next page of files under id: {}".format(parent_id))
                request_params['pageToken'] = json_response['nextPageToken']
                json_response = fetch_files(request_params)
                r = [e for e in json_response['files'] if e['name'] == next_name]
                if len(r) > 0:
                    return traverse_to_file(r[0]['id'], idx + 1)
        raise ValueError('Unable to find name: {}, under directory with id: {}'.format(next_name, parent_id))

    contents = traverse_to_file('root', 0)
    log.info("Propagating contents to file.managed: {}".format(contents))
    return delegate_to_file_managed(source=None, contents=contents)
