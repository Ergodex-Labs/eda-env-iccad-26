FROM openroad/orfs:26Q3-5-gfb65d5b48@sha256:699820f927f1bed72f3673047a5a58007c81d11365ea6fa5cb2cea9f13b61946

COPY evaluator/patched/ /OpenROAD-flow-scripts/flow/scripts/
ENV LEC_CHECK=0 QT_QPA_PLATFORM=offscreen NUM_CORES=8
RUN rm -rf /OpenROAD-flow-scripts/tools/install/kepler-formal && \
    sed -i 's/\[ord::openroad_gui_compiled\]/0/' /OpenROAD-flow-scripts/flow/scripts/final_report.tcl
RUN apt-get update && apt-get install -y --no-install-recommends iverilog=11.0-1.1 && \
    rm -rf /var/lib/apt/lists/* && \
    useradd --create-home --uid 1001 --shell /bin/bash agent
COPY evaluator/run_flow.sh /usr/local/bin/orfs-agent-run
RUN chmod 755 /usr/local/bin/orfs-agent-run && \
    test -f /usr/local/bin/eqy && command -v iverilog && command -v vvp
WORKDIR /workspace
