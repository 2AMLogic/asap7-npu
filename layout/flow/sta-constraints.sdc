# npu_top pre-route STA constraints (issue #80 bring-up).
#
# klt sta does not read this file as a constraint source -- the request
# (layout/flow/sta-request.json) is the only one. The request's sdc_check
# compares this file against the request's constraints so the two cannot
# drift silently.
#
# The 2.0 ns period is the layout flow's existing CLOCK_PERIOD_NS input
# (layout/flow/make-request.py: the 500 MHz fallback target; a flow input,
# not a claim). I/O delays are stated as 0.0 ns, the same values the
# place-and-route request carries (input_delay_ns 0, output_delay_ns 0).
create_clock -name clk -period 2.0 [get_ports clk]
set_input_delay 0.0 -clock clk [all_inputs]
set_output_delay 0.0 -clock clk [all_outputs]
