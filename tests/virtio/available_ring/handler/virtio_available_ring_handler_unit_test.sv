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

`include "svunit_defines.svh"

module virtio_available_ring_handler_unit_test;
    import svunit_pkg::svunit_testcase;
    import virtio_available_ring_pkg::*;

    string name = "virtio_available_ring_handler_unit_test";
    svunit_testcase svunit_ut;

    localparam int MAX_BURST_TRANSACTIONS = 16;
    localparam int NOTIFICATION_THRESHOLD_HIGH = 1024;
    localparam int NOTIFICATION_THRESHOLD_LOW = 16;

    logic aclk = 0;
    logic areset_n = 0;

    initial forever #1 aclk = ~aclk;

    logic_axi4_stream_if
    notify (.*);

    logic_axi4_stream_if
    configure (.*);

    logic_axi4_stream_if #(
        .TID_WIDTH($bits(response_t)),
        .TDATA_BYTES(2)
    ) rx (.*);

    logic_axi4_stream_if #(
        .TID_WIDTH($bits(request_t)),
        .TDATA_BYTES(4)
    ) tx (.*);

    virtio_available_ring_handler #(
        .MAX_BURST_TRANSACTIONS(MAX_BURST_TRANSACTIONS),
        .NOTIFICATION_THRESHOLD_HIGH(NOTIFICATION_THRESHOLD_HIGH),
        .NOTIFICATION_THRESHOLD_LOW(NOTIFICATION_THRESHOLD_LOW)
    )
    dut (
        .*
    );

    function void build();
        svunit_ut = new (name);
    endfunction

    task setup();
        svunit_ut.setup();

        areset_n = 0;
        @(posedge aclk);

        areset_n = 1;
        tx.cb_tx.tready <= 1;
        @(posedge aclk);
    endtask

    task teardown();
        svunit_ut.teardown();

        areset_n = 0;
        tx.cb_tx.tready <= 0;
    endtask

`SVUNIT_TESTS_BEGIN

`SVTEST(basic)
    fork
    begin
        byte data[] = new [1];

        @(notify.cb_rx);
        notify.cb_write(data);
    end
    begin
        byte data[];
        request_t request;

        tx.cb_read(data, REQUEST_READ_IDX);
        `FAIL_UNLESS_EQUAL(data.size(), 4)

        data = new [2] ('{16'd63});
        rx.cb_write(data);

        tx.cb_read(data, REQUEST_READ_IDS);
        `FAIL_UNLESS_EQUAL(data.size(), 4)
        request = {<<8{data}};
        `FAIL_UNLESS_EQUAL(request.offset, 0)
        `FAIL_UNLESS_EQUAL(request.length, 16)

        tx.cb_read(data, REQUEST_READ_IDS);
        `FAIL_UNLESS_EQUAL(data.size(), 4)
        request = {<<8{data}};
        `FAIL_UNLESS_EQUAL(request.offset, 16)
        `FAIL_UNLESS_EQUAL(request.length, 16)

        data = new [1];
        notify.cb_write(data);

        tx.cb_read(data, REQUEST_READ_IDS);
        `FAIL_UNLESS_EQUAL(data.size(), 4)
        request = {<<8{data}};
        `FAIL_UNLESS_EQUAL(request.offset, 32)
        `FAIL_UNLESS_EQUAL(request.length, 16)

        tx.cb_read(data, REQUEST_READ_IDS);
        `FAIL_UNLESS_EQUAL(data.size(), 4)
        request = {<<8{data}};
        `FAIL_UNLESS_EQUAL(request.offset, 48)
        `FAIL_UNLESS_EQUAL(request.length, 15)
    end
    join
`SVTEST_END

`SVUNIT_TESTS_END

endmodule
