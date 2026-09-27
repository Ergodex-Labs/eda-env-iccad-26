## Check of the ECP measurement against RDF-2024

EDA-env scores timing with the effective clock period (ECP). ECP is the
evaluation clock period minus the worst setup slack. This section shows that
the EDA-env measurement of ECP reproduces values that other authors published.

### What we measured

The RDF-2024 paper publishes 18 routed reference layouts on Nangate45, and the
ECP of each layout (Table 3 in Section 3.2 of that paper). The layouts cover
three designs (AES, Ibex, JPEG), two goals (performance and area), and three
flows (commercial, hybrid, OpenROAD). "Hybrid" is commercial synthesis and then
OpenROAD physical implementation. RDF-2024 writes this flow as OR*.

We measured the ECP of each of the 18 layouts with the EDA-env sign-off script.
We did not change a layout. No placement step and no routing step ran. Thus
the check compares the measurement setups. It does not compare design quality.

- Paper: V. A. Chhabria et al., "Strengthening the Foundations of IC Physical
  Design and ML EDA Research," ICCAD 2024,
  [doi:10.1145/3676536.3697136](https://doi.org/10.1145/3676536.3697136).
- Layouts: <https://github.com/ieee-ceda-datc/robust-design-flow> (commit `f869d99`).

### Result

Sixteen of the 18 measurements agree with the published ECP within 0.9%. These
measurements use the SDC file that comes with each layout.

The two exceptions are the JPEG layouts from the commercial flow. Their first
measurements were 27.8% and 54.6% less than the published values. The cause is
in the constraints, not in the layouts. The SDC files of these two layouts give
the input delays no clock binding. OpenSTA then leaves the input paths
unconstrained, and the measured period is too small. With the second
constraint set (below), the two measurements agree with the published values
within 0.023% and 0.004%.

### The two constraint sets

1. **Supplied SDC.** This is the SDC file that comes with each routed layout,
   with propagated clocks. The JSON files call this variant `gater`.
2. **Clock-bound template.** This set keeps the clock period of the supplied
   SDC. It gives zero input delay to each input that is not a clock, and zero
   output delay to each output. It binds each delay to the clock `clk`. RDF
   uses this style of constraints for its evaluation. The JSON files call this
   variant `autotune`.

The JSON files also contain the variants `rdf`, `ideal`, and `nolatency`. They
are different probes. The variant `rdf` is not the clock-bound template.

### The JPEG rows

All four rows are JPEG on Nangate45. The row number is the position of the row
in the published Table 3, counted from the first data row. It is not an
EDA-env task number. The last column gives the case name in the JSON file.

| RDF row | Goal / flow | Published ECP (ns) | Supplied SDC (ns) | Clock-bound template (ns) | JSON case |
|---|---|---:|---:|---:|---|
| 13 | Performance / commercial | 0.616 | 0.444821671 | 0.616141051 | `perf_comm` |
| 16 | Area / commercial | 14.725 | 6.684889038 | 14.725553400 | `area_comm` |
| 15 | Performance / hybrid | 0.899 | 0.898653193 | 0.898653193 | `perf_hybrid` |
| 18 | Area / hybrid | 2.138 | 2.136981146 | not measured | (none) |

- The paper says that the template "reproduces both published periods". This
  phrase means rows 13 and 16, the two commercial JPEG layouts.
- Row 15 is the control. Its ECP is the same with the two constraint sets.
- With the template, the worst paths of rows 13 and 16 go from the reset input
  to recovery checks.
- Row 18 is in the measurement of all 18 layouts. Its value is 2.13698 ns, and
  the published value is 2.138 ns. The difference is 0.048%.
- Row 18 was not in the smaller probe of the constraint variants. That probe
  used rows 13, 15, and 16 only. Thus row 18 has no value for the template.

### Measurement files

- `rdf-bounds-measured.json`: measurements of all 18 layouts under their supplied SDCs.
- `rdf-jpeg-probe-results.json`: five constraint variants on JPEG layouts 13, 15, and 16.

These files contain recorded calibration results. The release does not include the calibration scripts.
