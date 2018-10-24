#!py


def run():
  states = {}
  swaps = __salt__['mount.swaps']()
  for swap, dev in swaps.items():
    states["kubeadm_disable_swap_{}".format(swap)] = {
      'module.run': [
        { 'mount.swapoff': [
          { 'name': swap },
        ]},
        { 'require_in': [
          { 'pkg': "kubeadm" }
          ]}
      ]
    }
    #todo remove entries from fstab
    #currently this seems impossible as UUID is not recognized
#    entries = __salt__['mount.fstab']()
#    states["kubeadm_remove_swap_{}".format(swap)] = {
#      'module.run': [
#        { 'mount.rm_fstab': [
#          { 'name': "none" },
#          { 'device': swap },
#          ]},
#        { 'require': [
#          { 'module': "kubeadm_disable_swap_{}".format(swap) }
#        ]}
#      ]
#    }
  return states
