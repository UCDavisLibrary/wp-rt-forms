# Wordpress RT Forms

A small Wordpress instance that hosts forms for creating RT tickets. Hopefully a temporary solution - once the staff intranet gets a facelift, the forms can be moved there without a tremendous amount of effort.

## Local Development
To get this app up and running on your local machine, follow these steps:

   1. Create a directory called `rt-forms` or something like that. This will be our root directory. cd into it.
   2. Git clone this repository
   3. Git clone all repositories listed in the `ALL_GIT_REPOSITORIES` variable in `deploy/config.sh`. It is incumbent on you to check out the branches/tags you want to work on for these repositories.
   4. `cd wp-rt-forms/deploy`
   5. Download Google Cloud credentials by running `./cmds/init-reader-key.sh`
   6. Set up local environment with `./cmds/init-local-dev.sh`
   7. Build your local docker images with `./build-local-dev.sh`
   8. Generate deployment files with `./cmds/generate-deployment-files`. This will make the directory `wp-rt-forms-local-dev`. If you want to customize the port or similar settings, you can create an `.env` file here.
   9. `cd wp-rt-forms-local-dev` and then `docker compose up`

## Production Deployment

1. Ensure your config.sh has the correct versions.
2. Check in and tag your changes with git.
3. Run submit.sh to build your images in Google Cloud.
4. ssh veers.library.ucdavis.edu
5. cd /opt/wp-rt-forms && git pull
6. docker compose pull
7. docker compose down && docker compose up -d
