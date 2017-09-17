import copy
import logging
import os

import salt.ext.six as six
import salt.loader
import salt.utils
import salt.utils.dictupdate
import salt.utils.gitfs
from salt.exceptions import SaltConfigurationError
from salt.utils.gitfs import GitPillar

PER_REMOTE_OVERRIDES = ('env', 'root', 'ssl_verify', 'refspecs')
PER_REMOTE_ONLY = ('name', 'mountpoint')

log = logging.getLogger(__name__)

__virtualname__ = 'privgit'


def __virtual__():
    privgit_ext_pillars = [x for x in __opts__['ext_pillar'] if 'privgit' in x]
    if not privgit_ext_pillars:
        # No privgit configured, don't load then
        return False
    return __virtualname__


def ext_pillar(minion_id, pillar, *args, **kwargs):
    '''
    Custom git pillar that can be set up using previous pillars
    use:
    privgit_privkey_location
    privgit_pubkey_location
    to point to ssh keypair on master
    or 
    privgit_privkey
    privgit_pubkey
    with raw content to use (instead of *_location)
    :param minion_id: 
    :param pillar: 
    :param args: 
    :param kwargs: 
    :return: 
    '''

    def fail(ex): raise ex

    def from_pillar_then_opts_required(key):
        fallback_opts = [e[key] for e in args if key in e]
        return pillar[key] if key in pillar else fallback_opts[0] if len(fallback_opts) > 0 else fail(SaltConfigurationError("option: {} not found in configuration".format(key)))

    opts = copy.deepcopy(__opts__)
    cachedir = __salt__['config.get']('cachedir')

    if "privgit_privkey" in pillar and "privgit_pubkey" in pillar:
        parent = os.path.join(cachedir, 'privgit', minion_id)
        priv_location = os.path.join(parent, 'priv.key')
        pub_location = os.path.join(parent, 'pub.key')
        __salt__['file.write'](priv_location, pillar['privgit_privkey'])
        __salt__['file.write'](pub_location, pillar['privgit_pubkey'])
        pillar['privgit_privkey_location'] = priv_location
        pillar['privgit_pubkey_location'] = pub_location

    privgit_env = from_pillar_then_opts_required('privgit_env')
    privgit_root = from_pillar_then_opts_required('privgit_root')
    privgit_branch = from_pillar_then_opts_required('privgit_branch')
    privgit_repo = from_pillar_then_opts_required('privgit_url')
    privgit_privkey = from_pillar_then_opts_required('privgit_privkey_location')
    privgit_pubkey = from_pillar_then_opts_required('privgit_pubkey_location')

    repo = [{'{} {}'.format(privgit_branch, privgit_repo): [
        {"env": privgit_env},
        {"root": privgit_root},
        {"privkey": privgit_privkey},
        {"pubkey": privgit_pubkey}]}]
    log.debug("generated private git configuration: {}".format(repo))

    try:
        # this logic is shamelessly taken from: salt.pillar.git_pillar.ext_pillar
        # due to: https://github.com/saltstack/salt/issues/39978
        privgit = GitPillar(opts)
        privgit.init_remotes(repo, PER_REMOTE_OVERRIDES, PER_REMOTE_ONLY)
        if __opts__.get('__role') == 'minion':
            # If masterless, fetch the remotes. We'll need to remove this once
            # we make the minion daemon able to run standalone.
            privgit.fetch_remotes()
        privgit.update()  # performs fetch
        log.debug("{} fetch done".format(privgit_repo))
        privgit.checkout()

        ret = {}
        merge_strategy = __opts__.get(
            'pillar_source_merging_strategy',
            'smart'
        )
        merge_lists = __opts__.get(
            'pillar_merge_lists',
            False
        )
        for pillar_dir, env in six.iteritems(privgit.pillar_dirs):
            log.debug(
                'git_pillar is processing pillar SLS from %s for pillar '
                'env \'%s\'', pillar_dir, env
            )

            if env == '__env__':
                env = opts.get('pillarenv') \
                      or opts.get('environment') \
                      or opts.get('git_pillar_base')
                log.debug('__env__ maps to %s', env)

            pillar_roots = [pillar_dir]
            opts['pillar_roots'] = {env: pillar_roots}
            local_pillar = salt.pillar.Pillar(opts, __grains__, minion_id, env)
            ret = salt.utils.dictupdate.merge(
                ret,
                local_pillar.compile_pillar(ext=False),
                strategy=merge_strategy,
                merge_lists=merge_lists
            )
        return ret
    except Exception as e:
        log.error("Fatal error in privgit", str(e))
        return {}
