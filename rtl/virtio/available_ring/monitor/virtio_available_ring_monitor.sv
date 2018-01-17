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

/* Module: virtio_available_ring_monitor
 *
 * Virtio available ring monitor.
 *
 * Parameters:
 *  CAPACITY                - Maximum number of descriptor indexes transactions
 *                            that can be stored in buffer.
 *  MAX_DESCRIPTOR_INDEXES  - Maximum number of descriptor indexes per single
 *                            transaction.
 *
 * Ports:
 *  aclk        - Clock.
 *  areset_n    - Asynchronous active-low reset.
 *  monitor     - AXI4-Stream to monitor buffer for descriptor indexes.
 *  rx          - AXI4-Stream Rx interface for virtqueue requests.
 *  tx          - AXI4-Stream Tx interface for virtqueue requests.
 */
module virtio_available_ring_monitor #(
    int CAPACITY = 16,
    int MAX_DESCRIPTOR_INDEXES = 4,
    int ADDRESS_WIDTH = (CAPACITY >= 2) ? $clog2(CAPACITY) : 1,
    int OFFSET_WIDTH = (MAX_DESCRIPTOR_INDEXES >= 2) ?
        $clog2(MAX_DESCRIPTOR_INDEXES) : 1
) (
    input aclk,
    input areset_n,
    `LOGIC_MODPORT(logic_axi4_stream_if, monitor) monitor,
    `LOGIC_MODPORT(logic_axi4_stream_if, rx) rx,
    `LOGIC_MODPORT(logic_axi4_stream_if, tx) tx
);
    import virtio_available_ring_pkg::*;

    localparam int OFFSET = MAX_DESCRIPTOR_INDEXES - 1;
    localparam int CAPACITY_WIDTH = ADDRESS_WIDTH + 1;
    localparam int ALMOST_FULL = CAPACITY - 1;

    initial begin: design_rule_checks
        `LOGIC_DRC_POWER_OF_2(CAPACITY)
        `LOGIC_DRC_POWER_OF_2(MAX_DESCRIPTOR_INDEXES)
    end

    request_t request;

    logic read;
    logic write;
    logic [15:0] capacity_add_pre;
    logic [CAPACITY_WIDTH-1:0] capacity_add;
    logic [CAPACITY_WIDTH-1:0] capacity;
    logic almost_full;

    always_comb request = request_t'(rx.tdata);
    always_comb capacity_add_pre = request.offset + OFFSET[15:0];
    always_comb capacity_add = capacity_add_pre[OFFSET_WIDTH+:CAPACITY_WIDTH];

    always_comb write = rx.tvalid && tx.tready && !almost_full &&
        (REQUEST_READ_RING == request_type_t'(rx.tid));

    always_comb begin
        if (rx.tvalid) begin
            unique case (request_type_t'(rx.tid))
            REQUEST_READ_RING: begin
                rx.tready = tx.tready && !almost_full;
            end
            default: begin
                rx.tready = tx.tready;
            end
            endcase
        end
        else begin
            rx.tready = tx.tready;
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            almost_full <= '0;
        end
        else begin
            almost_full <= (capacity >= ALMOST_FULL[CAPACITY_WIDTH-1:0]);
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            read <= '0;
        end
        else begin
            read <= monitor.tvalid && monitor.tready;
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            capacity <= '0;
        end
        else if (write && !read) begin
            capacity <= capacity + capacity_add;
        end
        else if (!write && read) begin
            capacity <= capacity - 1'b1;
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            tx.tvalid <= '0;
        end
        else if (tx.tready) begin
            if (rx.tvalid) begin
                unique case (request_type_t'(rx.tid))
                REQUEST_READ_RING: begin
                    tx.tvalid <= !almost_full;
                end
                default: begin
                    tx.tvalid <= '1;
                end
                endcase
            end
            else begin
                tx.tvalid <= '0;
            end
        end
    end

    always_ff @(posedge aclk) begin
        if (tx.tready) begin
            tx.write(rx.read());
        end
    end

`ifdef VERILATOR
    logic _unused_signals = &{1'b0, request.length, 1'b0};
`endif
endmodule
