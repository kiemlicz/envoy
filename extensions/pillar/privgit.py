import collections
import copy
import logging
import os

import salt.ext.six as six
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
    Custom git pillar that can be set up in the runtime via other pillar data
    Read more at envoy README.md file
    Use:
    privkey_location
    pubkey_location
    to point to ssh keypair on master
    or 
    privkey
    pubkey
    with raw content (instead of *_location)
    '''

    def fail(ex): raise ex

    def read_configuration(key, d):
        return d[key] if key in d else fail(SaltConfigurationError("option: {} not found in configuration".format(key)))

    def deflatten_pillar():
        d = {}
        for e in (e for e in pillar if e.startswith('privgit_')):
            value = pillar[e]
            keys = e[9:].split('_', 1)
            d[keys[0]] = {
                keys[1]: value
            }
        return d

    def merge(input_dict, output_dict):
        for e in input_dict:
            output_dict.update(e)

    ext_name = 'privgit'
    opt_url = 'url'
    opt_branch = 'branch'
    opt_env = 'env'
    opt_root = 'root'
    opt_privkey = 'privkey'
    opt_pubkey = 'pubkey'
    opt_privkey_loc = 'privkey_location'
    opt_pubkey_loc = 'pubkey_location'

    opts = copy.deepcopy(__opts__)
    cachedir = __salt__['config.get']('cachedir')
    merge_strategy = __opts__.get(
        'pillar_source_merging_strategy',
        'smart'
    )
    merge_lists = __opts__.get(
        'pillar_merge_lists',
        False
    )
    repositories = collections.OrderedDict()

    merge(args, repositories)
    merge(pillar[ext_name], repositories)
    merge(deflatten_pillar(), repositories)

    ret = {}
    for repository_name, repository_opts in repositories:
        if opt_privkey in repository_opts and opt_pubkey in repository_opts:
            parent = os.path.join(cachedir, ext_name, minion_id, repository_name)
            priv_location = os.path.join(parent, 'priv.key')
            pub_location = os.path.join(parent, 'pub.key')
            __salt__['file.write'](priv_location, repository_opts[opt_privkey])
            __salt__['file.write'](pub_location, repository_opts[opt_pubkey])
            repository_opts[opt_privkey_loc] = priv_location
            repository_opts[opt_pubkey_loc] = pub_location

        privgit_url = read_configuration(opt_url, repository_opts)
        privgit_branch = read_configuration(opt_branch, repository_opts)
        privgit_env = read_configuration(opt_env, repository_opts)
        privgit_root = read_configuration(opt_root, repository_opts)
        privgit_privkey = read_configuration(opt_privkey_loc, repository_opts)
        privgit_pubkey = read_configuration(opt_pubkey_loc, repository_opts)
        repo = [{'{} {}'.format(privgit_branch, privgit_url): [
            {"env": privgit_env},
            {"root": privgit_root},
            {"privkey": privgit_privkey},
            {"pubkey": privgit_pubkey}]}]

        log.debug("generated private git configuration: {}".format(repo))
        try:
            ret = salt.utils.dictupdate.merge(
                ret,
                _privgit_clone(minion_id, opts, repo, merge_strategy, merge_lists),
                strategy=merge_strategy,
                merge_lists=merge_lists
            )
        except Exception as e:
            log.error("Fatal error in privgit, for: {} {}, repository will be omitted".format(privgit_branch, privgit_url), str(e))

    return ret


def _privgit_clone(minion_id, opts, repo_arg, merge_strategy, merge_lists):
    # this logic is shamelessly taken from: salt.pillar.git_pillar.ext_pillar
    # due to: https://github.com/saltstack/salt/issues/39978
    privgit = GitPillar(opts)
    privgit.init_remotes(repo_arg, PER_REMOTE_OVERRIDES, PER_REMOTE_ONLY)
    if __opts__.get('__role') == 'minion':
        # If masterless, fetch the remotes. We'll need to remove this once
        # we make the minion daemon able to run standalone.
        privgit.fetch_remotes()
    privgit.update()  # performs fetch
    log.debug("{} fetch done".format(repo_arg))
    privgit.checkout()

    ret = {}
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
