ARG FROM=ubuntu:18.04
FROM $FROM
# ======================================
# Stage base
# ======================================

USER root

# Some tools that are always good to have
RUN apt-get update && apt-get install -y git wget unzip vim rsync

# AI Training requirements
ARG WORKSPACE_DIR=/workspace
RUN mkdir $WORKSPACE_DIR && \
    chown 42420:42420 $WORKSPACE_DIR && \
    addgroup --gid 42420 ovh && \
    useradd --uid 42420 -g ovh --shell /bin/bash -d $WORKSPACE_DIR ovh

# Configuration for ovh user
USER ovh
WORKDIR /workspace

# AI Training CLI : ovhai
RUN wget https://cli.gra.training.ai.cloud.ovh.net/ovhai-linux.zip && \
    unzip ovhai-linux.zip && rm ovhai-linux.zip && \
    chmod a+x ovhai && mkdir -p /$WORKSPACE_DIR/.local/bin && mv ovhai /$WORKSPACE_DIR/.local/bin/

# For loading .bashrc even through ssh or jupyter terminal
RUN echo "if [ -f ~/.bashrc ]; then . ~/.bashrc ; fi" > .bash_profile

ENV PATH=$WORKSPACE_DIR/.local/bin:$PATH
ENV LANG=C.UTF-8
ENV SHELL=/bin/bash
SHELL ["/bin/bash", "-c"]


# ======================================
# Stage conda
# ======================================

ARG MINICONDA_URL=https://repo.anaconda.com/miniconda/Miniconda3-py38_4.10.3-Linux-x86_64.sh
ARG MINICONDA_PATH=/miniconda3

USER root
RUN mkdir -p $(dirname $MINICONDA_PATH) && \
    wget $MINICONDA_URL -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p $MINICONDA_PATH && \
    rm /tmp/miniconda.sh

# We set the base environment
# For root (for the rest of the build process)
USER root
RUN bash -c "$MINICONDA_PATH/bin/conda init bash"

# And for ovh (for the run time)
USER ovh
RUN bash -c "$MINICONDA_PATH/bin/conda init bash"

# So the conda config is available in the rest of the building process
SHELL ["/bin/bash", "-il", "-c"]


# ======================================
# Stage jupyterlab
# ======================================

USER root

COPY assets/install_tools.sh /tmp/install_tools.sh
RUN /tmp/install_tools.sh && rm /tmp/install_tools.sh

# install nvm
# https://github.com/creationix/nvm#install-script
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash

ENV NVM_DIR /root/.nvm
ENV NODE_VERSION v12.20.1

# install node and npm
RUN source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/versions/node/$NODE_VERSION/bin
ENV PATH $NODE_PATH:$PATH

# Set up a python inqstallation especially for jupyter, so it does not interfere with other python installations
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py37_4.10.3-Linux-x86_64.sh -O /tmp/miniconda.sh
RUN bash /tmp/miniconda.sh -b -p /lab && rm /tmp/miniconda.sh


# Install Jupyter
RUN /lab/bin/pip install pip==20.3.4 && \
    /lab/bin/pip install jupyterlab==2.2.9 ipywidgets==7.6.3 && \
    /lab/bin/jupyter labextension install @jupyter-widgets/jupyterlab-manager && \
    /lab/bin/jupyter nbextension enable --py widgetsnbextension #enable ipywidgets

COPY assets/jupyter.sh /usr/bin/aitraining_entrypoint.sh

# Uninstalls the kernel in the lab environment
# We dont want the users to work there
RUN rm -rf /lab/share/jupyter/kernels/python3/


# Installation of the ipykernel in the main python environment if it not already installed
USER ovh
# The name python3 is important if you want the /lab environment to be excluded from the launcher
# If the kernel is already installed, it does nothing
RUN if [[ $(/lab/bin/jupyter kernelspec list | grep 'python3 */usr/local/share/jupyter/kernels/python3') ]] ; \
    then echo "Existing kernel found, we skip kernel installation." ; \
    else python -m pip install ipykernel && ipython kernel install --name python3 --display-name "Main Python" --user --env PATH "$(dirname $( which python )):$PATH"; \
    fi

# ======================================
# Stage user files
# ======================================


USER ovh
RUN mkdir /workspace && chown -R 42420:42420 /workspace
WORKDIR /workspace
COPY requirements.txt requirements.txt
COPY workspace/* ./
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8080
ENTRYPOINT []
CMD ["/usr/bin/aitraining_entrypoint.sh"]
