FROM jupyter/minimal-notebook

LABEL maintainer="Pierre Navaro <navaro@math.cnrs.fr>"

USER root

# Julia dependencies
# install Julia packages in /opt/julia instead of $HOME
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_VERSION=1.0.2

RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION} | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz
RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

# Show Julia where conda libraries are \
RUN mkdir /etc/julia && \
    echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" >> /etc/julia/juliarc.jl && \
    # Create JULIA_PKGDIR \
    mkdir $JULIA_PKGDIR && \
    chown $NB_USER $JULIA_PKGDIR && \
    fix-permissions $JULIA_PKGDIR

COPY . ${HOME}
RUN chown -R ${NB_UID} ${HOME}
USER $NB_UID

RUN julia -e 'import Pkg; Pkg.update()' && \
    julia -e 'import Pkg; Pkg.add("IJulia")' && \
    # Precompile Julia packages \
    julia -e 'using IJulia' && \
    # move kernelspec out of home \
    mv $HOME/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
    chmod -R go+rx $CONDA_DIR/share/jupyter && \
    rm -rf $HOME/.local && \
    fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter

RUN conda create -n conda_jl python conda && \
    conda install -q -y matplotlib -n conda_jl -c conda-forge  && \
    export CONDA_JL_HOME=${CONDA_DIR}/envs/conda_jl && \
    julia -e 'import Pkg; Pkg.build("Conda")'

RUN cd ${HOME} && julia -q ${HOME}/deps_install.jl
