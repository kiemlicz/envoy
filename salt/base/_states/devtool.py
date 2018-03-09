import logging
import os


def managed(name, download_url, destination_dir, user, group, enforce_toplevel=True, saltenv='base'):
    '''
    Wrapper for archive.extracted
    Adds symlink to 'name' location
    '''
    ret = {'name': name, 'changes': {}, 'result': False, 'comment': ''}
    log = logging.getLogger(__name__)

    def _format_comments(comments):
        '''
        Return a joined list
        '''
        ret = '. '.join(comments)
        if len(comments) > 1:
            ret += '.'
        return ret

    def _fail(ret, msg, comments=None):
        ret['result'] = False
        if comments:
            msg += '\n\nFailure reason: '
            msg += _format_comments(comments)
        ret['comment'] = msg
        return ret

    # listing before extraction as archive.extracted has bug and requires to pass enforce_ownership_on:
    # https://github.com/saltstack/salt/issues/38605

    archive_contents = __salt__['archive.list'](download_url)
    extract_dir = os.path.commonprefix(archive_contents)  # relative path
    if not extract_dir and not enforce_toplevel:
        return _fail(ret, "Cannot find root directory in extracted archive, try setting enforce_toplevel: True", archive_contents)
    extract_location = os.path.join(destination_dir, extract_dir)
    log.debug("Will extract to: {0}".format(extract_location))

    # since 2016.11 archive_format is no longer needed

    # todo check if user/group may be left for windows or will cause failure
    extract_result = __states__['archive.extracted'](name=destination_dir, source=download_url, user=user, group=group,
                                                     enforce_ownership_on=extract_location, skip_verify=True, trim_output=50)
    if not extract_result['result']:
        return _fail(ret, "Cannot extract archive from: {0}".format(download_url), [extract_result['comment']])

    old_state = ["{0} previously didn't exist".format(download_url)]
    if not extract_result['changes']:
        # was already downloaded
        old_state = ["{0} was already extracted in {1}\n".format(download_url, destination_dir)]

    symlink_result = __states__['file.symlink'](name=name, target=extract_location, user=user)
    if not symlink_result['result']:
        return _fail(ret, "Cannot create symlink ({0}) to: {1}".format(name, extract_location))

    ret['comment'] = "Success"
    ret['changes'].update({'devtool': {
        'old': old_state,
        'new': ["Extracted to: {0}".format(extract_location)]
    }})
    ret['result'] = True
    return ret