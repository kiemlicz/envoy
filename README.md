[![Build status](https://travis-ci.org/kiemlicz/envoy.svg?branch=master)](https://travis-ci.org/kiemlicz/envoy)
# Basics 
[SaltStack](https://saltstack.com/) _states_ for provisioning machines in the most generic way possible.  
The goal is to create _salt environments_ usable by developers as well as admins during the setup of either server or 'client' machines.

## Setup  
There are multiple options to deploy **envoy**.  
They depend on how you want to provision machines:  
 1. Separate `salt-master` process provisioning `salt-minions`:  
Refer to SaltStack documentation of [gitfs](https://docs.saltstack.com/en/latest/topics/tutorials/gitfs.html) 
(if you prefer local filesystem then familiarize with [multienv](https://docs.saltstack.com/en/latest/ref/states/top.html)) or use 
fully automated setup of SaltStack via associated [project ambassador](https://github.com/kiemlicz/ambassador)

 2. Master-less provisioning (machine provisions itself):  
 **Steps**
    1. `curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com`
    2. `sh /tmp/bootstrap-salt.sh stable 2017.7.1`
    3. Use `config/masterless.conf` (put under `/etc/salt/minion.d/`) 

## Components
In order to run _states_ against _minions_, _pillar_ must be configured.  
Refer to `pillar.example.sls` files in states themselves for particular structure.  
_States_ must be written with assumption that given pillar entry may not exist.
`users` dict contains data (mostly self-describing) about particular... user.
However some sections need more description:
#### sec 
Designed to generate/copy user security keys/keypairs.  
For now only ssh is supported. When only `privkey_location` and `pubkey_location` is defined then keypair is generated on _minion_.
On the other hand, if `privkey` and `pubkey` is also defined then its content is used as keys. Content can be passed also using 'flat' pillar 
of following form: `<username>_sec_ssh_<name>_privkey` (in our example main keypair can be specified using: `coolguy_sec_ssh_home_privkey: <key>`)
#### dotfile 
TODO
 
# Structure
States are divided in environments:
 1. `base` - the main one. Any other environment comprises of at least `base`. Contains core states responsible for operations like
 repositories configuration, core packages installation or user setup
 2. `gui` - for machines using graphical interface. Uses `base`. Contains states ensuring that e.g. window manager is installed (or your favorite gui apps).
 3. `dev` - for developer machines. Uses `gui` and `base`. Contains states that install tons of dev apps as well as configures them (like add entry to `PATH` variable)
 4. `server` - TODO
 5. `qa` - TODO
 7. `prod` - TODO

# Extensions
In order to keep _states_ readable and configuration of whole SaltStack as flexible as possible, some extensions were introduced:
## privgit
Dynamically configured `ext_pillar`.  
Allows users to configure their own _pillar_ data git repository (in the runtime - using pillar entries)
Repository must contain pillar data under the `root` directory
### Usage
Fully static configuration (use _git_pillar_ instead of such):
```
ext_pillar:
  - privgit:
    - name1:
      url: git@github.com:someone/somerepo.git
      branch: master  
      env: custom
      root: pillar
      privkey: |
      some
      sensitive data
      pubkey: and so on
    - name2:
      url: git@github.com:someone/somerepo.git
      branch: develop
      env: custom
      privkey_location: /location/on/master
      pubkey_location: /location/on/master
```
Each of such parameter can be overridden in _pillar_ data that comes before _ext_pillar_:
```
privgit:
  - name1:
    url: git@github.com:someone/somerepo.git
    branch: master  
    env: custom
    root: pillar
    privkey: |
    some
    sensitive data
    pubkey: and so on
  - name2:
    url: git@github.com:someone/somerepo.git
    branch: develop
    env: custom
    privkey_location: /location/on/master
    pubkey_location: /location/on/master
  - name2:
    url: git@github.com:someone/somerepo.git
    branch: notdevelop
```
Entries order does matter, last one is the most specific one. It doesn't affect further pillar merge strategies.
They rely on salt settings only

Due to potential integration with systems like [foreman](https://theforeman.org/) that support string keys only, 
another (unpleasant) syntax exists:
```
privgit_name1_url: git@github.com:someone/somerepo.git
privgit_name1_branch: master 
privgit_name1_env: custom
privgit_name1_root: pillar
privgit_name1_privkey: |
        some
        sensitive data
privgit_name1_pubkey: and so on
privgit_name2_url: git@github.com:someone/somerepo.git
privgit_name2_branch: develop
privgit_name2_env: custom
privgit_name2_privkey_location: /location/on/master
privgit_name2_pubkey_location: /location/on/master
``` 

## dotfile
Custom _state_ that manages [dotfiles](https://en.wikipedia.org/wiki/Dot-file).  
Clones them from passed repository and sets up according to following [technique](https://developer.atlassian.com/blog/2016/02/best-way-to-store-dotfiles-git-bare-repo/)
## devtool
Most dev tools setup comes down to downloading some kind of archive, unpacking it and possibly adding symlink to some generic location.  
This state does pretty much that.
## envops
Environment variables operations.
 
# References
1. SaltStack [quickstart](https://docs.saltstack.com/en/latest/topics/states/index.html)
2. SaltStack [best practices](https://docs.saltstack.com/en/latest/topics/best_practices.html)
