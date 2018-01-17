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

/* Package: virtio_available_ring_pkg
 *
 * Virtio available ring package
 */
package virtio_available_ring_pkg;
    /* Struct: configuration_t
     *
     * Configuration.
     *
     * event_idx    - VIRTIO_F_EVENT_IDX was negotiated.
     */
    typedef struct packed {
        logic event_idx;
    } configuration_t;

    /* Struct: request_type_t
     *
     * Request type.
     *
     * REQUEST_READ_RING        - Request type to read descriptor indexes from
     *                            available ring.
     * REQUEST_READ_IDX         - Request type to read idx field from
     *                            available ring.
     * REQUEST_READ_USED_EVENT  - Request type to read used_event field from
     *                            available ring.
     */
    typedef enum logic [1:0] {
        REQUEST_READ_RING,
        REQUEST_READ_IDX,
        REQUEST_READ_USED_EVENT
    } request_type_t;

    /* Struct: request_t
     *
     * Request data.
     *
     * length   - Number of descriptor indexes to read from available ring.
     * offset   - Index offset from available ring base address.
     */
    typedef struct packed {
        logic [15:0] length;
        logic [15:0] offset;
    } request_t;

    /* Struct: response_type_t
     *
     * Response type. See request_type_t.
     */
    typedef request_type_t response_type_t;

    /* Struct: response_t
     *
     * Response data.
     *
     * offset       - Index offset from available ring base address.
     */
    typedef struct packed {
        logic [15:0] offset;
    } response_t;
endpackage
