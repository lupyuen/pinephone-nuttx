// Test Code for MIPI DSI
// Add `#include "../../pinephone-nuttx/test/test_mipi_dsi.c"` to the end of this file:
// https://github.com/lupyuen2/wip-pinephone-nuttx/blob/dsi/arch/arm64/src/a64/mipi_dsi.c

void mipi_dsi_test(void)  //// TODO: Remove
{
    // Allocate Packet Buffer
    uint8_t pkt_buf[128];
    memset(pkt_buf, 0, sizeof(pkt_buf));

    // Test Compose Short Packet (Without Parameter)
    ginfo("Testing Compose Short Packet (Without Parameter)...\n");
    const uint8_t short_pkt[1] = {
        0x11,
    };
    const ssize_t short_pkt_result = mipi_dsi_short_packet(
        pkt_buf,  //  Packet Buffer
        sizeof(pkt_buf),  // Packet Buffer Size
        0,         //  Virtual Channel
        MIPI_DSI_DCS_SHORT_WRITE, // DCS Command
        short_pkt,    // Transmit Buffer
        sizeof(short_pkt)  // Buffer Length
    );
    ginfo("Result:\n");
    ginfodumpbuffer("pkt_buf", pkt_buf, short_pkt_result);

    const uint8_t expected_short_pkt[] = { 
      0x05, 0x11, 0x00, 0x36 
    };
    DEBUGASSERT(short_pkt_result == sizeof(expected_short_pkt));
    DEBUGASSERT(memcmp(pkt_buf, expected_short_pkt, sizeof(expected_short_pkt)) == 0);

    // Write to MIPI DSI
    // _ = nuttx_mipi_dsi_dcs_write(
    //     null,  //  Device
    //     0,     //  Virtual Channel
    //     MIPI_DSI_DCS_SHORT_WRITE, // DCS Command
    //     &short_pkt,    // Transmit Buffer
    //     short_pkt.len  // Buffer Length
    // );

    // Test Compose Short Packet (With Parameter)
    ginfo("Testing Compose Short Packet (With Parameter)...\n");
    const uint8_t short_pkt_param[2] = {
        0xbc, 0x4e,
    };
    const ssize_t short_pkt_param_result = mipi_dsi_short_packet(
        pkt_buf,  //  Packet Buffer
        sizeof(pkt_buf),  // Packet Buffer Size
        0,         //  Virtual Channel
        MIPI_DSI_DCS_SHORT_WRITE_PARAM, // DCS Command
        short_pkt_param,    // Transmit Buffer
        sizeof(short_pkt_param)  // Buffer Length
    );
    ginfo("Result:\n");
    ginfodumpbuffer("pkt_buf", pkt_buf, short_pkt_param_result);

    const uint8_t expected_short_pkt_param[] = { 
        0x15, 0xbc, 0x4e, 0x35 
    };
    DEBUGASSERT(short_pkt_param_result == sizeof(expected_short_pkt_param));
    DEBUGASSERT(memcmp(pkt_buf, expected_short_pkt_param, sizeof(expected_short_pkt_param)) == 0);

    // Write to MIPI DSI
    // _ = nuttx_mipi_dsi_dcs_write(
    //     null,  //  Device
    //     0,     //  Virtual Channel
    //     MIPI_DSI_DCS_SHORT_WRITE_PARAM, // DCS Command
    //     &short_pkt_param,    // Transmit Buffer
    //     short_pkt_param.len  // Buffer Length
    // );

    // Test Compose Long Packet
    ginfo("Testing Compose Long Packet...\n");
    const uint8_t long_pkt[] = {
        0xe9, 0x82, 0x10, 0x06, 0x05, 0xa2, 0x0a, 0xa5,
        0x12, 0x31, 0x23, 0x37, 0x83, 0x04, 0xbc, 0x27,
        0x38, 0x0c, 0x00, 0x03, 0x00, 0x00, 0x00, 0x0c,
        0x00, 0x03, 0x00, 0x00, 0x00, 0x75, 0x75, 0x31,
        0x88, 0x88, 0x88, 0x88, 0x88, 0x88, 0x13, 0x88,
        0x64, 0x64, 0x20, 0x88, 0x88, 0x88, 0x88, 0x88,
        0x88, 0x02, 0x88, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    };
    const ssize_t long_pkt_result = mipi_dsi_long_packet(
        pkt_buf,  //  Packet Buffer
        sizeof(pkt_buf),  // Packet Buffer Size
        0,         //  Virtual Channel
        MIPI_DSI_DCS_LONG_WRITE, // DCS Command
        long_pkt,    // Transmit Buffer
        sizeof(long_pkt)  // Buffer Length
    );
    ginfo("Result:\n");
    ginfodumpbuffer("pkt_buf", pkt_buf, long_pkt_result);

    const uint8_t expected_long_pkt[] = {
        0x39, 0x40, 0x00, 0x25, 0xe9, 0x82, 0x10, 0x06,
        0x05, 0xa2, 0x0a, 0xa5, 0x12, 0x31, 0x23, 0x37,
        0x83, 0x04, 0xbc, 0x27, 0x38, 0x0c, 0x00, 0x03,
        0x00, 0x00, 0x00, 0x0c, 0x00, 0x03, 0x00, 0x00,
        0x00, 0x75, 0x75, 0x31, 0x88, 0x88, 0x88, 0x88,
        0x88, 0x88, 0x13, 0x88, 0x64, 0x64, 0x20, 0x88,
        0x88, 0x88, 0x88, 0x88, 0x88, 0x02, 0x88, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x65, 0x03,
    };
    DEBUGASSERT(long_pkt_result == sizeof(expected_long_pkt));
    DEBUGASSERT(memcmp(pkt_buf, expected_long_pkt, sizeof(expected_long_pkt)) == 0);
}
