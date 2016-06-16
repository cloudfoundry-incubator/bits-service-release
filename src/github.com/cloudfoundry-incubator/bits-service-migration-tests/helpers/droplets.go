package helpers

import (
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
)

func DropletContext(config helpers.Config) cf.UserContext {
	return cf.NewUserContext(
		config.ApiEndpoint,
		config.AdminUser,
		config.AdminPassword,
		"BSMT-droplet-test-org",
		"BSMT-droplet-test-space",
		true)
}
