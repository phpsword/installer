![Sword Logo](./sword-logo-sm.png)

<br>

[![Github Workflow](https://github.com/phpsword/installer/workflows/Installer%20builder/badge.svg)](https://github.com/phpsword/installer/actions)

# Documentation
Visit https://getsword.com for user and developer documentation.

This repository builds a Docker installer for Sword.

The generated installer creates an up-to-date Sword project with a full
Docker development environment.

To create a new Sword project, simply run this one-liner:

```bash
docker run --rm --pull=always -t -e HOST_PWD="$PWD" \
    -v "$PWD":/app -v /var/run/docker.sock:/var/run/docker.sock \
    phpsword/installer myproject
```

Replace `myproject` by the name of your project. Done!

# Contributions
Feel free to submit issues and pull requests.

# License
[MIT](LICENSE)

Copyright (c) 2022-present, William Arin
