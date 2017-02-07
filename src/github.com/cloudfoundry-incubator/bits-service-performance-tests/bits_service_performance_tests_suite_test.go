package main_test

import (
	"time"

	statsd "gopkg.in/alexcesaro/statsd.v2"

	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"testing"
)

var (
	context        helpers.SuiteContext
	config         helpers.Config
	defaultTimeout time.Duration = 30 * time.Second
	cfPushTimeout  time.Duration = 5 * time.Minute
	statsdClient   *statsd.Client
)

func TestBitsServicePerformanceTests(t *testing.T) {
	config = helpers.LoadConfig()

	if config.DefaultTimeout > 0 {
		defaultTimeout = config.DefaultTimeout * time.Second
	}

	if config.CfPushTimeout > 0 {
		cfPushTimeout = config.CfPushTimeout * time.Second
	}

	context = helpers.NewContext(config)
	environment := helpers.NewEnvironment(context)

	BeforeSuite(func() {
		environment.Setup()

		var e error
		statsdClient, e = statsd.New() // Connect to the UDP port 8125 by default.
		Expect(e).NotTo(HaveOccurred())
	})

	AfterSuite(func() {
		statsdClient.Close()
		environment.Teardown()
	})

	RegisterFailHandler(Fail)
	RunSpecs(t, "BitsServicePerformanceTests Suite")
}
