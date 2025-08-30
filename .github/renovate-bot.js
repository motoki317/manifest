module.exports = {
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "username": "moto-renovate[bot]",
  "gitAuthor": "moto-renovate <138499486+moto-renovate[bot]@users.noreply.github.com>",
  "platform": "github",
  "repositories": ["motoki317/manifest"],
  "hostRules": [
    {
      "hostType": "docker",
      "matchHost": "ghcr.io",
      "username": "motoki317",
      "password": process.env.RENOVATE_DOCKER_TOKEN,
    }
  ],
}
