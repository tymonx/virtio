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

/* Module: virtio_available_ring_handler
 *
 * Virtio available ring handler.
 *
 * Parameters:
 *  MAX_BURST_TRANSACTIONS      - Maximum number of burst transactions.
 *  NOTIFICATION_THRESHOLD_HIGH - Notification suppression threshold high bound.
 *  NOTIFICATION_THRESHOLD_LOW  - Notification suppression threshold low bound.
 *
 * Ports:
 *  aclk        - Clock.
 *  areset_n    - Asynchronous active-low reset.
 *  configure   - AXI4-Stream interface for virtqueue configuration.
 *  notify      - AXI4-Stream interface for virtqueue notification.
 *  rx          - AXI4-Stream interface for virtqueue responses.
 *  tx          - AXI4-Stream interface for virtqueue requests.
 */
module virtio_available_ring_handler #(
    int MAX_BURST_TRANSACTIONS = 16,
    int NOTIFICATION_THRESHOLD_HIGH = 1024,
    int NOTIFICATION_THRESHOLD_LOW = 16
) (
    input aclk,
    input areset_n,
    `LOGIC_MODPORT(logic_axi4_stream_if, rx) configure,
    `LOGIC_MODPORT(logic_axi4_stream_if, rx) notify,
    `LOGIC_MODPORT(logic_axi4_stream_if, rx) rx,
    `LOGIC_MODPORT(logic_axi4_stream_if, tx) tx
);
    import virtio_available_ring_pkg::*;

    initial begin: design_rule_checks
        `LOGIC_DRC_EQUAL_OR_GREATER_THAN(MAX_BURST_TRANSACTIONS, 1)
        `LOGIC_DRC_LESS_THAN(NOTIFICATION_THRESHOLD_LOW,
            NOTIFICATION_THRESHOLD_HIGH)
    end

    enum logic [1:0] {
        FSM_IDLE,
        FSM_EVENT_IDX,
        FSM_READ_POINTER,
        FSM_DIFFERENCE
    } fsm_state;

    logic read;
    logic write;
    logic [15:0] write_pointer;
    logic [15:0] read_pointer;
    logic [15:0] difference;
    logic [15:0] ids;
    logic not_empty;

    logic threshold_low;
    logic threshold_high;

    logic notification;
    logic notification_set;
    logic notification_clear;

    logic suppression;
    logic suppression_set;
    logic suppression_clear;

    configuration_t configuration;

    request_type_t request_type;
    request_t request;
    response_t response;

    always_comb notification_set = notify.tvalid;
    always_comb notification_clear = (FSM_IDLE == fsm_state) &&
        notification && !suppression && tx.tready;

    always_comb response = response_t'(rx.tdata);

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            rx.tready <= '0;
        end
        else begin
            rx.tready <= '1;
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            notify.tready <= '0;
        end
        else begin
            notify.tready <= '1;
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            configure.tready <= '0;
        end
        else begin
            configure.tready <= '1;
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            configuration <= '0;
        end
        else if (configure.tvalid) begin
            configuration <= configuration_t'(configure.tdata);
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            notification <= '0;
        end
        else if (notification_set) begin
            notification <= '1;
        end
        else if (notification_clear) begin
            notification <= '0;
        end
    end

    always_comb write = rx.tvalid;

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            write_pointer <= '0;
        end
        else if (write) begin
            write_pointer <= response.offset;
        end
    end

    always_comb read = (FSM_IDLE == fsm_state) && tx.tready &&
        !(notification && !suppression) && not_empty;

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            read_pointer <= '0;
        end
        else if (read) begin
            read_pointer <= read_pointer + ids;
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            difference <= '0;
        end
        else begin
            difference <= write_pointer - read_pointer;
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            ids <= '0;
        end
        else begin
            ids <= (difference < MAX_BURST_TRANSACTIONS[15:0])
                ? difference : MAX_BURST_TRANSACTIONS[15:0];
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            not_empty <= '0;
        end
        else begin
            not_empty <= (0 != difference);
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            threshold_low <= '0;
        end
        else begin
            threshold_low <= (difference <= NOTIFICATION_THRESHOLD_LOW[15:0]);
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            threshold_high <= '0;
        end
        else begin
            threshold_high <= (difference >= NOTIFICATION_THRESHOLD_HIGH[15:0]);
        end
    end

    always_comb suppression_set = !suppression && threshold_high;
    always_comb suppression_clear = suppression && threshold_low;

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            suppression <= '0;
        end
        else if (suppression_set) begin
            suppression <= '1;
        end
        else if (suppression_clear) begin
            suppression <= '0;
        end
    end

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            fsm_state <= FSM_IDLE;
        end
        else if (tx.tready) begin
            unique case (fsm_state)
            FSM_IDLE: begin
                if (notification && !suppression) begin
                    if (configuration.event_idx) begin
                        fsm_state <= FSM_EVENT_IDX;
                    end
                end
                else if (not_empty) begin
                    fsm_state <= FSM_READ_POINTER;
                end
            end
            FSM_EVENT_IDX: begin
                fsm_state <= FSM_IDLE;
            end
            FSM_READ_POINTER: begin
                fsm_state <= FSM_DIFFERENCE;
            end
            default: begin
                fsm_state <= FSM_IDLE;
            end
            endcase
        end
    end

    always_comb begin
        unique case (fsm_state)
        FSM_IDLE: begin
            request_type = (notification && !suppression) ?
                REQUEST_READ_IDX : REQUEST_READ_RING;
        end
        FSM_EVENT_IDX: begin
            request_type = REQUEST_READ_USED_EVENT;
        end
        default: begin
            request_type = REQUEST_READ_RING;
        end
        endcase
    end

    always_comb request = '{
        length: ids,
        offset: read_pointer
    };

    always_ff @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            tx.tvalid <= 1'b0;
        end
        else if (tx.tready) begin
            unique case (fsm_state)
            FSM_IDLE: begin
                tx.tvalid <= (notification && !suppression) || not_empty;
            end
            FSM_EVENT_IDX: begin
                tx.tvalid <= 1'b1;
            end
            default: begin
                tx.tvalid <= 1'b0;
            end
            endcase
        end
    end

    always_ff @(posedge aclk) begin
        if (tx.tready) begin
            tx.tid <= request_type;
            tx.tdata <= request;
        end
    end

    always_comb tx.tdest = '0;
    always_comb tx.tuser = '0;
    always_comb tx.tlast = '1;
    always_comb tx.tkeep = '1;
    always_comb tx.tstrb = '1;
endmodule
