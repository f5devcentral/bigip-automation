{
  "schemaVersion": "3.50.1",
  "path_${name}": {
    "class": "Application",
    "${name}": {
      "class": "Service_HTTP",
      "virtualAddresses": [
        "${virtualIP}"
      ],
      ${virtualPort == 0 ? "\"virtualPort\": 80," : "\"virtualPort\": ${virtualPort},"}
      "pool": "pool_${name}"
    },
    "pool_${name}": {
      "class": "Pool",
      "members": [
        {
          "servicePort": ${servicePort},
          "shareNodes": true,
          "serverAddresses": ${jsonencode(serverAddresses)}
        }
      ]
    }
  }
}

