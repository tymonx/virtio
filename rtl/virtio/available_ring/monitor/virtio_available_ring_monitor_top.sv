/* Copyright 2018 Tymoteusz Blazejczyk
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

`include "logic.svh"

module virtio_available_ring_monitor_top #(
    int CAPACITY = 16,
    int MAX_DESCRIPTOR_INDEXES = 4
) (
    input aclk,
    input areset_n,
    /* Monitor */
    input monitor_tlast,
    input monitor_tvalid,
    input [0:0][7:0] monitor_tdata,
    input [0:0] monitor_tstrb,
    input [0:0] monitor_tkeep,
    input [0:0] monitor_tdest,
    input [0:0] monitor_tuser,
    input [0:0] monitor_tid,
    input monitor_tready,
    /* Rx */
    input rx_tlast,
    input rx_tvalid,
    input [3:0][7:0] rx_tdata,
    input [3:0] rx_tstrb,
    input [3:0] rx_tkeep,
    input [0:0] rx_tdest,
    input [0:0] rx_tuser,
    input [1:0] rx_tid,
    output logic rx_tready,
    /* Tx */
    output logic tx_tlast,
    output logic tx_tvalid,
    output logic [3:0][7:0] tx_tdata,
    output logic [3:0] tx_tstrb,
    output logic [3:0] tx_tkeep,
    output logic [0:0] tx_tdest,
    output logic [0:0] tx_tuser,
    output logic [1:0] tx_tid,
    input tx_tready
);
    logic_axi4_stream_if
    monitor (.*);

    logic_axi4_stream_if #(
        .TDATA_BYTES(4),
        .TID_WIDTH(2)
    ) rx (.*);

    logic_axi4_stream_if #(
        .TDATA_BYTES(4),
        .TID_WIDTH(2)
    ) tx (.*);

    always_comb monitor.tvalid = monitor_tvalid;
    always_comb monitor.tready = monitor_tready;
    always_comb monitor.tlast = monitor_tlast;
    always_comb monitor.tdest = monitor_tdest;
    always_comb monitor.tuser = monitor_tuser;
    always_comb monitor.tstrb = monitor_tstrb;
    always_comb monitor.tkeep = monitor_tkeep;
    always_comb monitor.tdata = monitor_tdata;
    always_comb monitor.tid = monitor_tid;

    `LOGIC_AXI4_STREAM_IF_RX_ASSIGN(rx, rx);

    virtio_available_ring_monitor #(
        .CAPACITY(CAPACITY),
        .MAX_DESCRIPTOR_INDEXES(MAX_DESCRIPTOR_INDEXES)
    )
    unit (
        .*
    );

    `LOGIC_AXI4_STREAM_IF_TX_ASSIGN(tx, tx);
endmodule
