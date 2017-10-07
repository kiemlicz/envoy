from __future__ import print_function

import json
import logging
import os

import salt.config
import salt.utils.locales
from google.auth.transport.urllib3 import AuthorizedHttp
from google.oauth2.credentials import Credentials
from salt.exceptions import CommandExecutionError
from salt.ext import six
from salt.ext.six.moves.urllib.parse import urlparse

log = logging.getLogger(__name__)


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

    authorized_http = _gdrive_connection()
    location = _source_to_gdrive_location_list(source)
    log.debug("Asserting path: {}".format(location))
    contents = _download_file(authorized_http, _traverse_to(authorized_http, location))

    log.info("Propagating contents to file.managed: {}".format(contents))
    return delegate_to_file_managed(source=None, contents=contents)


def recurse(name,
            source,
            keep_source=True,  # not yet supported in 2017.7
            clean=False,
            require=None,
            user=None,
            group=None,
            dir_mode=None,
            file_mode=None,
            sym_mode=None,
            template=None,
            context=None,
            replace=True,  # not yet supported in 2017.7
            defaults=None,
            include_empty=False,
            backup='',
            include_pat=None,
            exclude_pat=None,
            maxdepth=None,
            keep_symlinks=False,
            force_symlinks=False,
            **kwargs):
    '''
    State that extends file.recurse with new source scheme (`gdrive://`)
    If other than `gdrive://` scheme is used, execution is delegated to `file.recurse` state
    '''
    ret = {
        'name': name,
        'changes': {},
        'pchanges': {},
        'result': True,
        'comment': {}  # { path: [comment, ...] }
    }

    def delegate_to_file_recurse():
        return __states__['file.recurse'](name, source, clean, require, user, group, dir_mode, file_mode, sym_mode,
                                          template, context, defaults, include_empty, backup, include_pat,
                                          exclude_pat, maxdepth, keep_symlinks, force_symlinks, **kwargs)

    def delegate_to_file_managed(path, contents, replace):
        return __states__['file.managed'](path,
                                          source=None,
                                          user=user,
                                          group=group,
                                          mode=file_mode,
                                          template=template,
                                          makedirs=True,
                                          replace=replace,
                                          defaults=defaults,
                                          backup=backup,
                                          contents=contents,
                                          **kwargs)

    def delegate_to_file_directory(path):
        return __states__['file.directory'](path,
                                            user=user,
                                            group=group,
                                            recurse=[],
                                            dir_mode=dir_mode,
                                            file_mode=file_mode,
                                            makedirs=True,
                                            clean=False,
                                            require=None)

    def add_comment(path, comment):
        comments = ret['comment'].setdefault(path, [])
        if isinstance(comment, six.string_types):
            comments.append(comment)
        else:
            comments.extend(comment)

    def merge_ret(path, _ret):
        # Use the most "negative" result code (out of True, None, False)
        if _ret['result'] is False or ret['result'] is True:
            ret['result'] = _ret['result']

        # Only include comments about files that changed
        if _ret['result'] is not True and _ret['comment']:
            add_comment(path, _ret['comment'])

        if _ret['changes']:
            ret['changes'][path] = _ret['changes']

    def manage_file(path, replace, fileid):
        if clean and os.path.exists(path) and os.path.isdir(path) and replace:
            _ret = {'name': name, 'changes': {}, 'result': True, 'comment': ''}
            if __opts__['test']:
                _ret['comment'] = u'Replacing directory {0} with a ' \
                                  u'file'.format(path)
                _ret['result'] = None
                merge_ret(path, _ret)
                return
            else:
                __salt__['file.remove'](path)
                _ret['changes'] = {'diff': 'Replaced directory with a '
                                           'new file'}
                merge_ret(path, _ret)

        try:
            c = _export_file(authorized_http, fileid)
            _ret = delegate_to_file_managed(path, c, replace)
        except Exception as e:
            _ret = {
                'name': name,
                'changes': {},
                'result': False,
                'comment': str(e)
            }
        merge_ret(path, _ret)

    def manage_directory(path):
        _ret = delegate_to_file_directory(path)
        merge_ret(path, _ret)

    source = salt.utils.locales.sdecode(source)
    if urlparse(source).scheme != 'gdrive':
        return delegate_to_file_recurse()

    authorized_http = _gdrive_connection()
    location = _source_to_gdrive_location_list(source)
    source_id = _traverse_to(authorized_http, location)
    dir_hierarchy = _walk_dir(authorized_http, source_id)
    log.debug("google drive walk result: {}".format(dir_hierarchy))

    def handle(file_list, absolute_dest_path):
        manage_directory(absolute_dest_path)
        for f in file_list:
            dest = os.path.join(absolute_dest_path, f['name'])
            if 'content' in f:
                handle(f['content'], dest)
            else:
                manage_file(dest, replace, f['id'])

    handle(dir_hierarchy, name)
    return ret


def _source_to_gdrive_location_list(source):
    source = urlparse(source)
    p = source.netloc + source.path
    return p.strip(os.sep).split(os.sep)


def _walk_dir(auth_http, start_id):
    def merge(indict):
        indict.update({'content': _walk_dir(auth_http, indict['id'])})
        return indict

    return [(merge(e) if e['mimeType'] == 'application/vnd.google-apps.folder' else e) for e in
            _list_children(auth_http, start_id)]


def _traverse_to(auth_http, path_segment_list):
    '''
    Asserts that path_segment_list exists on the google drive

    :return: id of file/folder traversed to (the last one in the path_segment_list)
    '''

    def go(parent_id, idx):
        if idx >= len(path_segment_list):
            return parent_id
        next_name = path_segment_list[idx]
        file_list = _list_children(auth_http, parent_id)
        r = [e for e in file_list if e['name'] == next_name]
        if len(r) > 0:
            # don't care if name occurred in other pages or already multiple times
            return go(r[0]['id'], idx + 1)
        raise ValueError('Unable to find name: {}, under directory with id: {}'.format(next_name, parent_id))

    if not path_segment_list:
        return 'root'
    else:
        return go('root', 0)


def _list_children(auth_http, parent_id):
    def query(extra_params=None):
        request_params = {
            'q': "'{}' in parents".format(parent_id)
        }
        if extra_params is not None:
            request_params.update(extra_params)
        r = json.loads(
            auth_http.request('GET', 'https://www.googleapis.com/drive/v3/files', fields=request_params).data)
        _assert_incomplete_search(r)
        return r

    json_response = query()
    ret_list = json_response['files']
    while 'nextPageToken' in json_response:
        log.debug("Fetching next page of files under id: {}".format(parent_id))
        json_response = query({'pageToken': json_response['nextPageToken']})
        ret_list.extend(json_response['files'])
    return ret_list


def _export_file(auth_http, file_id, mime_type='text/plain'):
    log.debug("Exporting file id: {}".format(file_id))
    return _do_get(auth_http, 'https://www.googleapis.com/drive/v3/files/{}/export'.format(file_id), {'mimeType': mime_type})


def _download_file(auth_http, file_id):
    log.debug("Downloading file id: {}".format(file_id))
    return _do_get(auth_http, 'https://www.googleapis.com/drive/v3/files/{}?alt=media'.format(file_id))


def _do_get(auth_http, url, params={}):
    response = auth_http.request('GET', url, fields=params)
    if response.status >= 400:
        raise CommandExecutionError('Unable to download file (url: {}), reason: {}'.format(url, response.data))
    return response.data


def _gdrive_connection():
    config = __salt__['config.get']('google_api')
    token_url = config['token_url']
    client_id = config['client_id']
    client_secret = config['client_secret']
    token = __salt__['pillar.get']("gdrive")
    log.debug("Token retrieved: {}".format(token))

    if not isinstance(token, dict):
        raise CommandExecutionError('Improper token format, does the google token exist?')

    credentials = Credentials(token[u'access_token'],
                              refresh_token=token[u'refresh_token'],
                              token_uri=token_url,
                              client_id=client_id,
                              client_secret=client_secret)
    return AuthorizedHttp(credentials)


def _assert_incomplete_search(json_response):
    if json_response['incompleteSearch']:
        raise CommandExecutionError('google drive query ended due to incompleteSearch')
