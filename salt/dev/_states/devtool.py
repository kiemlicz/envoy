import logging
import os

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

def managed(name, download_url, destination_dir, user, group, saltenv='base'):

    ret = {'name': name, 'changes': {}, 'result': False, 'comment': ''}
    log = logging.getLogger(__name__)

    #since 2016.11 archive_format is no longer needed

    #todo check if user/group may be left for windows or will cause failure
    extract_result = __states__['archive.extracted'](name=destination_dir, source=download_url, user=user, group=group,
                                        skip_verify=True, trim_output=50)
    #todo verify it always extracts
    if not extract_result['result']:
        return _fail(ret, "Cannot extract archive from: {0}".format(download_url), [extract_result['comment']])

    old_state=["{0} previously didn't exist".format(download_url)]
    if not extract_result['changes']:
        #was already downloaded
        old_state=["{0} was already extracted in {1}\n".format(download_url, destination_dir)]

    archive_contents = __salt__['archive.list'](download_url)
    extracted_dir = os.path.commonprefix(archive_contents) #relative path
    if not extracted_dir:
        return _fail(ret, "Cannot find root directory in extracted archive", archive_contents)

    extracted_location = os.path.join(destination_dir,extracted_dir)
    log.debug("Extracted to: {0}".format(extracted_location))
    symlink_result = __states__['file.symlink'](name=name, target=extracted_location, user=user)
    if not symlink_result['result']:
        return _fail(ret, "Cannot create symlink ({0}) to: {1}".format(name, extracted_location))

    ret['comment'] = "Success"
    ret['changes'].update({'devtool': {
        'old': old_state,
        'new': ["Extracted to: {0}".format(extracted_location)]
    }})
    ret['result'] = True
    return ret
