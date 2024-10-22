const { packetDecode } = require("2stools-daq");

module.exports = function (RED) {
  function tosense(config) {
    RED.nodes.createNode(this, config);
    var node = this;

    node.on("input", function (msg) {
      let payload;

      if (msg.payload.payload_raw) {
        payload = msg.payload.payload_raw;
      } else {
        payload = msg.payload;
      }

      msg.payload = packetDecode(payload, msg.offset);
      node.send(msg);
    });
  }

  RED.nodes.registerType("2stools-packetdecode", tosense);
};
