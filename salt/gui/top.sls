gui:
  'gpus:vendor:nvidia':
    - match: grain
    - nvidia_driver

  '*':
    - keepass
    - owncloud
    - dropbox
    - spotify
