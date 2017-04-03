gui:
  'gpus:vendor:nvidia':
    - match: grain
    - nvidia

  '*':
    - keepass
    - owncloud
    - dropbox
    - spotify
