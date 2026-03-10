# CMock Docker environment for development

A Docker-based virtual development environment based on Arch. The container uses SSH keys from the host OS, loaded as Read-only when starting the container (executing `./run.sh`), allowing to use host OS SSH authentication. Keys are not persistent in the image, and are only injected when starting the container. The only persistent things in the image is the workspace and the configuration scripts placed inside the image during building. The environment comes with pre-configured Vim with Clangd support. The `run.sh` is configured to clean up the container when you call `exit` from inside, to avoid any hanging running containers. The container does not affect any files or settings on your host OS.

# Instruction

1. Install Docker for your host OS;

2. Generate your SSH keys on the host OS if you don't have any yet, and add them in your GitHub account settings to be able to contribute;

3. Fork the CMock repository, so that the Docker environment can resolve it from your GitHub and clone the fork into the workspace during first run.

4. Create `.env` file locally in your cloned repository, with `GIT_USER_NAME` and `GIT_USER_EMAIL` variables set;
    Example:
    ```
    // .env
    GIT_USER_NAME=TheJourneymansGuide
    GIT_USER_EMAIL=k.woj.coding@gmail.com
    ```
    This allows `git` inside the container to resolve your fork of the CMock repo, and to know what user name and e-mail to use when you commit something;

5. Run `./setup.sh` - this will create a docker volume for workspace persistance on your local machine, and will create the environment image;

6. Run `./run.sh` - this will start the image. If the CMock repository is not present in workspace, it will automatically get cloned during the first start.

7. \* If you would like to attach to the container with a second terminal, the `attach.sh` script will automatically resolve your current cmock-dev-arch instance and connect to it (executed as: `./attach.sh`);

> __IMPORTANT__: Be careful when you run multiple terminals in the same container. If you close the 'root' terminal that started the container, it will kill the container and subsequently disconnect all the other terminals from it.

> __NOTE__: Make sure you have Unicode-compliant font to enable the fish terminal to display symbols instead of rectangles. Example fonts are `Fira Code` and `Cascadia Code`.
