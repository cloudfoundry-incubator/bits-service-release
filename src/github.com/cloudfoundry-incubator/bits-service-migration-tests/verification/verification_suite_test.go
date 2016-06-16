package verification_test

import (
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"testing"
)

var (
	context        helpers.SuiteContext
	config         helpers.Config
	defaultTimeout time.Duration = 30 * time.Second
	cfPushTimeout  time.Duration = 2 * time.Minute
)

func TestVerification(t *testing.T) {
	RegisterFailHandler(Fail)

	config = helpers.LoadConfig()

	if config.DefaultTimeout > 0 {
		defaultTimeout = config.DefaultTimeout * time.Second
	}

	if config.CfPushTimeout > 0 {
		cfPushTimeout = config.CfPushTimeout * time.Second
	}

	context = helpers.NewPersistentAppContext(config)
	environment := helpers.NewEnvironment(context)

	BeforeSuite(func() {
		environment.Setup()
	})

	componentName := "Buildpacks"

	rs := []Reporter{}

	if config.ArtifactsDirectory != "" {
		helpers.EnableCFTrace(config, componentName)
		rs = append(rs, helpers.NewJUnitReporter(config, componentName))
	}

	RunSpecsWithDefaultAndCustomReporters(t, componentName, rs)
}
