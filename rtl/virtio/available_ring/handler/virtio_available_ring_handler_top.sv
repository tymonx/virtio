/* Copyright 2017 Tymoteusz Blazejczyk
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

module virtio_available_ring_handler_top #(
    int MAX_BURST_TRANSACTIONS = 16,
    int NOTIFICATION_THRESHOLD_HIGH = 1024,
    int NOTIFICATION_THRESHOLD_LOW = 16
) (
    input aclk,
    input areset_n,
    /* Configure */
    input configure_tlast,
    input configure_tvalid,
    input [0:0][7:0] configure_tdata,
    input [0:0] configure_tstrb,
    input [0:0] configure_tkeep,
    input [0:0] configure_tdest,
    input [0:0] configure_tuser,
    input [0:0] configure_tid,
    output logic configure_tready,
    /* Notify */
    input notify_tlast,
    input notify_tvalid,
    input [0:0][7:0] notify_tdata,
    input [0:0] notify_tstrb,
    input [0:0] notify_tkeep,
    input [0:0] notify_tdest,
    input [0:0] notify_tuser,
    input [0:0] notify_tid,
    output logic notify_tready,
    /* Rx */
    input rx_tlast,
    input rx_tvalid,
    input [1:0][7:0] rx_tdata,
    input [1:0] rx_tstrb,
    input [1:0] rx_tkeep,
    input [0:0] rx_tdest,
    input [0:0] rx_tuser,
    input [0:0] rx_tid,
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
    configure (.*);

    logic_axi4_stream_if
    notify (.*);

    logic_axi4_stream_if #(
        .TDATA_BYTES(2)
    ) rx (.*);

    logic_axi4_stream_if #(
        .TDATA_BYTES(4),
        .TID_WIDTH(2)
    ) tx (.*);

    `LOGIC_AXI4_STREAM_IF_RX_ASSIGN(configure, configure);
    `LOGIC_AXI4_STREAM_IF_RX_ASSIGN(notify, notify);
    `LOGIC_AXI4_STREAM_IF_RX_ASSIGN(rx, rx);

    virtio_available_ring_handler #(
        .MAX_BURST_TRANSACTIONS(MAX_BURST_TRANSACTIONS),
        .NOTIFICATION_THRESHOLD_HIGH(NOTIFICATION_THRESHOLD_HIGH),
        .NOTIFICATION_THRESHOLD_LOW(NOTIFICATION_THRESHOLD_LOW)
    )
    unit (
        .*
    );

    `LOGIC_AXI4_STREAM_IF_TX_ASSIGN(tx, tx);
endmodule
