FROM simexp/octave:4.2.1_cross_u16

# MAINTAINER Pierre-Olivier Quirion <poq@criugm.qc.ca>

ENV PSOM_VERSION 2.3.1
ENV NIAK_ROOT /usr/local/niak
ENV NIAK_CONFIG_PATH /local_config
ENV NIAK_SANDBOX_ROOT /sandbox
ENV NIAK_SANDBOX ${NIAK_SANDBOX_ROOT}/home
ENV TERM xterm-256color

# Install NIAK

RUN mkdir ${NIAK_ROOT}
COPY bricks/ ${NIAK_ROOT}/bricks/
COPY commands/ ${NIAK_ROOT}/commands/
COPY demos/ ${NIAK_ROOT}/demos/
COPY reports/ ${NIAK_ROOT}/reports/
COPY pipeline/ ${NIAK_ROOT}/pipeline/
COPY template/ ${NIAK_ROOT}/template/
COPY extensions/ ${NIAK_ROOT}/extensions/
WORKDIR  ${NIAK_ROOT}/extensions
RUN wget --progress=dot:giga https://sites.google.com/site/bctnet/Home/functions/BCT.zip \
    && unzip BCT.zip \
    && rm BCT.zip \
    && wget --progress=dot:giga https://github.com/SIMEXP/psom/archive/v${PSOM_VERSION}.zip \
    && unzip v${PSOM_VERSION}.zip \
    && rm v${PSOM_VERSION}.zip \
    && cd /usr/local/bin \
    && ln -s ../niak/extensions/psom-${PSOM_VERSION}/psom_worker.py psom_worker.py \
    && ln -s ../niak/extensions/psom-${PSOM_VERSION}/container/psom_image_exec_redirection.sh psom_image_exec_redirection.sh \
    && ln -s ../niak/util/bin/niak_cmd.py niak_cmd.py \
    && mkdir /scratch
# Build octave configure file
RUN mkdir ${NIAK_CONFIG_PATH} && chmod 777 ${NIAK_CONFIG_PATH} \
    && echo COPYpath\(genpath\(\'${NIAK_ROOT}\'\)\)\; >> /etc/octave.conf \
    && echo COPYpath\(genpath\(\'${NIAK_CONFIG_PATH}\'\)\)\; >> /etc/octave.conf

# niak will run here
RUN mkdir -p ${NIAK_SANDBOX} && chmod -R 777 ${NIAK_SANDBOX_ROOT}
WORKDIR ${NIAK_SANDBOX}

# 3D visualisation tools
RUN apt-get update && apt-get install --no-install-recommends --force-yes -y python-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# jupyter install
RUN wget --progress=dot:giga https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    pip install notebook octave_kernel && rm get-pip.py && \
    python -m octave_kernel.install && \
    pip install ipywidgets widgetsnbextension
COPY util/bin/niak_jupyter /usr/local/bin/niak_jupyter
COPY util/lib/psom_gb_vars_local.jupyter /usr/local/lib/psom_gb_vars_local.jupyter
COPY util/lib/jupyter_notebook_config.py /usr/local/lib/jupyter_notebook_config.py
EXPOSE 8080


# To run with jupyter
# docker run -it --rm  -v /niak_sandbox:$PWD --user $UID -p 8080:6666 simexp/niak-cog niak_jupyter


# Command to run octave as GUI
# docker run -it --privileged --rm -v /etc/group:/etc/group -v /etc/passwd:/etc/passwd   -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY -v $HOME:$HOME --user $UID simexp/niak-boss /bin/bash -lic "cd $HOME/software; octave --force-gui ; /bin/bash"

# Bids app setup
RUN pip install pyyaml
ENV PYTHONPATH=/code/util
RUN ln -s $NIAK_ROOT /code
ENV TMPDIR=/outputs/tmp
ENV HOME ${TMPDIR}

ENV NIAK_CONFIG_PATH /outputs/tmp/local_config
RUN mkdir /oasis /projects  /local-scratch
WORKDIR /tmp
ENTRYPOINT ["/code/util/bin/bids_app.py"]
CMD ["--help"]
COPY util/  ${NIAK_ROOT}/util/
