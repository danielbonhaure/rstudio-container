
##################################################################
##                           README                             ##
##################################################################
## Este Dockerfile permite crear un contendor con un entorno de ##
## desarrollo con RStudio completamente configurado.            ##
##################################################################



###########################
## Set GLOBAL BUILD ARGS ##
###########################

# Set R version
ARG R_VERSION="4.3"

# Set user name and id
ARG USR_NAME="nonroot"
ARG USER_UID="1001"  # el usuario rstudio ya tiene el UID 1000

# Set group name and id
ARG GRP_NAME="nonroot"
ARG USER_GID="1001"  # el grupo rstudio ya tiene el GID 1000

# Set users passwords
ARG ROOT_PWD="root"
ARG USER_PWD=${USR_NAME}



#################################
## Stage 1: Install R packages ##
#################################

# Create image
FROM rocker/rstudio:${R_VERSION} AS rstudio_builder

# set environment variables
ARG DEBIAN_FRONTEND=noninteractive

# Install OS packages
RUN apt-get -y -qq update && \
    apt-get -y -qq upgrade && \
    apt-get -y -qq --no-install-recommends install \
        build-essential \
        # to install httr (R)
        libcurl4-openssl-dev \
        # to install RPostgreSQL (R)
        libpq-dev \
        # to install ncdf4 (R)
        libnetcdf-dev \
        # to install sf (R)
        # to install terra, a dependency of sf and raster (R)
        libgdal-dev libgeos-dev libproj-dev \
        # to install classInt, a dependency of sf (R)
        gfortran \
        # to install units, a dependency of sf (R)
        libudunits2-dev \
        # to install ragg, a dependency of devtools (R)
        libharfbuzz-dev libfribidi-dev \
        # to install redux (R)
        libhiredis-dev && \
    rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "options(warn=2); install.packages('devtools', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('dplyr', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('dbplyr', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('DBI', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('fs', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('glue', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('gstat', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('here', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('httr', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('jsonlite', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('lmomco', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('lubridate', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('magrittr', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('ncdf4', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('purrr', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('raster', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('readr', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('redux', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('rlang', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('RPostgreSQL', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('sf', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('stringr', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('testthat', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('terra', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('tibble', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('tidyr', verbose=T, quiet=T, keep_outputs='/tmp/')" \
 && R -e "options(warn=2); install.packages('yaml', verbose=T, quiet=T, keep_outputs='/tmp/')"



##############################################
## Stage 2: Copy the R installation folders ##
##############################################

# Create image
FROM rstudio_builder AS rstudio_core

# set environment variables
ARG DEBIAN_FRONTEND=noninteractive

# Install OS packages
RUN apt-get -y -qq update && \
    apt-get -y -qq upgrade && \
    apt-get -y -qq --no-install-recommends install \
        # to be able to use httr (R)
        libcurl4-openssl-dev \
        # to be able to use RPostgreSQL (R)
        libpq-dev \
        # to be able to use ncdf4 (R)
        libnetcdf-dev \
        # to be able to use sf (R)
        # to be able to use sf and raster (R)
        libgdal-dev libgeos-dev libproj-dev \
        # to be able to use redux (R)
        libhiredis-dev && \
    rm -rf /var/lib/apt/lists/*

# Install R packages from rstudio_builder
# https://forums.docker.com/t/using-multi-stage-docker-build-for-slimming-down-images-with-r-dependency/67967
RUN mkdir -p /usr/local/lib/R \
             /usr/local/lib/R/site-library
COPY --from=rstudio_builder /usr/local/bin/R /usr/local/bin/R
COPY --from=rstudio_builder /usr/local/bin/Rscript /usr/local/bin/Rscript
COPY --from=rstudio_builder /usr/local/lib/R /usr/local/lib/R
COPY --from=rstudio_builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library
COPY --from=rstudio_builder /tmp /tmp

# Set R libs paths (see: https://stat.ethz.ch/R-manual/R-devel/library/base/html/libPaths.html)
ENV R_LIBS="/usr/local/lib/R/library"
ENV R_LIBS_USER="/usr/local/lib/R/site-library"
ENV R_LIBS_SITE="/usr/local/lib/R/site-library"



#############################################
## Stage 3: Install management OS packages ##
#############################################

# Create image
FROM rstudio_core AS rstudio_final

# Set environment variables
ARG DEBIAN_FRONTEND=noninteractive

# Install OS packages
RUN apt-get -y -qq update && \
    apt-get -y -qq upgrade && \
    apt-get -y -qq --no-install-recommends install \
        # to see process with pid 1
        htop procps \
        # to allow edit files
        vim \
        # to show progress through pipelines
        pv \
        # to clone Git projects
        git \
        # to download files
        curl wget \
        # to access redis \
        redis-tools && \
    rm -rf /var/lib/apt/lists/*



###################################################
## Stage 4: Setup final RStudio image (for ROOT) ##
###################################################

# Import final image
FROM rstudio_final AS rstudio_root_final

# Set environment variables
ARG DEBIAN_FRONTEND=noninteractive

# Create RStudio Projects folder
RUN mkdir -p /home/rstudio/RStudioProjects

# Run the S6 Overlay INIT, para entender porque ENTRYPOINT [ "/init" ], ver: 
# https://github.com/just-containers/s6-overlay, aunque rocker/rstudio usa CMD, ver:
# https://github.com/rocker-org/rocker-versioned2/blob/master/dockerfiles/rstudio_4.1.2.Dockerfile
ENTRYPOINT [ "/init" ]

# Set work directory
WORKDIR /home/rstudio

# Resulta que la imagen rocker/rstudio usa s6-overlay, y como se explica aquí:
# https://github.com/rocker-org/shiny/issues/79#issuecomment-633067470
# el "process supervisor" s6-overlay debe correr como root. Sin embargo
# se modificó la imagen para que rstudio corra siempre como no root
USER root

# AUTHORIZATION
# Al acceder a RStudio se solicita usuario y contraseña, las opciones válidas
# son dos: 1- usuario "rstudio", con la clave que se imprime en el log; y 
# 2- usuario "rstudio" con la clave definida por la variable de entorno PASSWORD.



###################################
## Stage 5: Create non-root user ##
###################################

# Create image
FROM rstudio_final AS rstudio_nonroot_builder

# Renew USER args
ARG USR_NAME
ARG USER_UID
ARG GRP_NAME
ARG USER_GID
ARG ROOT_PWD
ARG USER_PWD

# Install OS packages
RUN apt-get -y -qq update && \
    apt-get -y -qq upgrade && \
    apt-get -y -qq --no-install-recommends install \
        # to run sudo
        sudo && \
    rm -rf /var/lib/apt/lists/*

    # Modify root password
    RUN echo "root:${ROOT_PWD}" | chpasswd

# Create a non-root user, so the container can run as non-root
# OBS: the UID and GID must be the same as the user that own the
# input and the output volumes, so there isn't perms problems!!
# Se recomienda crear usuarios en el contendor de esta manera,
# ver: https://nickjanetakis.com/blog/running-docker-containers-as-a-non-root-user-with-a-custom-uid-and-gid
# Se agregar --no-log-init para prevenir un problema de seguridad,
# ver: https://jtreminio.com/blog/running-docker-containers-as-current-host-user/
RUN groupadd --gid ${USER_GID} ${GRP_NAME}
RUN useradd --no-log-init --uid ${USER_UID} --gid ${USER_GID} --shell /bin/bash \
    --comment "Non-root User Account" --create-home ${USR_NAME}

# Modify the password of non-root user
RUN echo "${USR_NAME}:${USER_PWD}" | chpasswd

# Add non-root user to sudoers and to adm group
# The adm group was added to allow non-root user to see logs
RUN usermod -aG sudo ${USR_NAME} && \
    usermod -aG adm ${USR_NAME}



#############################################################
## Stage 5: Setup final RStudio image (for NON-ROOT users) ##
#############################################################

# Import final image
FROM rstudio_nonroot_builder AS rstudio_nonroot_final

# Set environment variables
ARG DEBIAN_FRONTEND=noninteractive

# Renew ARGs
ARG USR_NAME

# Create RStudio Projects folder
RUN mkdir -p /home/${USR_NAME}/RStudioProjects

# Run the S6 Overlay INIT, para entender porque ENTRYPOINT [ "/init" ], ver: 
# https://github.com/just-containers/s6-overlay, aunque rocker/rstudio usa CMD, ver:
# https://github.com/rocker-org/rocker-versioned2/blob/master/dockerfiles/rstudio_4.1.2.Dockerfile
ENTRYPOINT ["/init"]

# Set work directory
WORKDIR /home/${USR_NAME}

# Resulta que la imagen rocker/rstudio usa s6-overlay, y como se explica aquí:
# https://github.com/rocker-org/shiny/issues/79#issuecomment-633067470
# el "process supervisor" s6-overlay debe correr como root. Sin embargo
# se modificó la imagen para que rstudio corra siempre como no root
USER root

# AUTHORIZATION
# Al acceder a RStudio se solicita usuario y contraseña, las opciones válidas
# son dos: 1- usuario "rstudio", con la clave que se imprime en el log; y 
# 2- usuario non-root creado y la contraseña definida para ese usuario.



#####################################################
## Usage: Commands to Build and Run this container ##
#####################################################


# BUILD RSTUDIO IMAGE (when user has UID and GID equals to 1000)
#
# docker build --pull \
# --target rstudio_root_final \
# --tag rstudio-ide:latest \
# --file Dockerfile .

# RUN RSTUDIO CONTAINER (when user has UID and GID equals to 1000)
#
# docker run \
# --name RStudioIDE \
# --env PASSWORD=rstudio \
# --mount type=bind,source="$(pwd)"/RStudioProjects,target=/home/rstudio/RStudioProjects \
# --publish 127.0.0.1:8787:8787 \
# --workdir /home/rstudio/RStudioProjects \
# --detach --rm crcsas-rstudio:latest


# BUILD RSTUDIO IMAGE (when user has UID and GID differents to 1000)
#
# docker build --pull \
# --target rstudio_nonroot_final \
# --tag rstudio-ide:latest \
# --build-arg USER_UID=$(stat -c "%u" .) \
# --build-arg USER_GID=$(stat -c "%g" .) \
# --file Dockerfile .

# RUN RSTUDIO CONTAINER (when user has UID and GID differents to 1000)
#
# docker run \
# --name RStudioIDE \
# --env PASSWORD=rstudio \
# --mount type=bind,source="$(pwd)"/RStudioProjects,target=/home/rstudio/RStudioProjects \
# --publish 127.0.0.1:8787:8787 \
# --workdir /home/rstudio/RStudioProjects \
# --detach --rm crcsas-rstudio:latest
