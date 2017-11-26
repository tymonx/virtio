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

/* Module: virtio_available_ring_handler_main
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
    logic areset_n_synced;

    logic_reset_synchronizer
    reset_synchronizer (
        .*
    );

    virtio_available_ring_handler_main #(
        .MAX_BURST_TRANSACTIONS(MAX_BURST_TRANSACTIONS),
        .NOTIFICATION_THRESHOLD_HIGH(NOTIFICATION_THRESHOLD_HIGH),
        .NOTIFICATION_THRESHOLD_LOW(NOTIFICATION_THRESHOLD_LOW)
    )
    main (
        .areset_n(areset_n_synced),
        .*
    );
endmodule
