# Caravel User Project

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![UPRJ_CI](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml) [![Caravel Build](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml)

| :exclamation: Important Note            |
|-----------------------------------------|

Overview
========

YONGA-100M Ethernet is based on the implementation of Alex Forencich's 100Mbps Ethernet design.

Setup
========

```bash
export PDK_ROOT=<pdk-installation-path>
export OPENLANE_ROOT=<openlane-installation-path>
cd $UPRJ_ROOT
export CARAVEL_ROOT=$(pwd)/caravel
make install
```

Running Simulation
========

### GPIO Test

* This test is meant to verify that we can send and receive data from YONGA-100M Ethernet through GPIO pins. The firmware sends a UDP frame to YONGA-100M Ethernet, then receives a response from YONGA-100M Ethernet.

To run RTL simulation, 

```bash
cd $UPRJ_ROOT
make verify-ethernet_100m
```

Hardening the User Project Macro using OpenLANE
========

```bash
# Run openlane to harden user_proj_example
make user_proj_example
# Run openlane to harden user_project_wrapper
make user_project_wrapper
```

Checklist for Open-MPW Submission
=================================

-  ✔️ The project repo adheres to the same directory structure in this
   repo.
-  ✔️ The project repo contain info.yaml at the project root.
-  ✔️ Top level macro is named ``user_project_wrapper``.
-  ✔️ Full Chip Simulation passes for RTL and GL (gate-level)
-  ✔️ The hardened Macros are LVS and DRC clean
-  ✔️ The project contains a gate-level netlist for ``user_project_wrapper`` at verilog/gl/user_project_wrapper.v
-  ✔️ The hardened ``user_project_wrapper`` adheres to the same pin
   order specified at
   `pin\_order <https://github.com/efabless/caravel/blob/master/openlane/user_project_wrapper_empty/pin_order.cfg>`__
-  ✔️ The hardened ``user_project_wrapper`` adheres to the fixed wrapper configuration specified at `fixed_wrapper_cfgs <https://github.com/efabless/caravel/blob/master/openlane/user_project_wrapper_empty/fixed_wrapper_cfgs.tcl>`__
-  ✔️ XOR check passes with zero total difference.
-  ✔️ Openlane summary reports are retained under ./signoff/
-  ✔️ The design passes the `mpw-precheck <https://github.com/efabless/mpw_precheck>`

List of Contributors
=================================

*In alphabetical order:*

- Abdullah Yildiz
- Burak Yakup Cakar
