package main_test

import (
	"fmt"
	"time"

	"github.com/tecnickcom/statsd"

	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"github.com/onsi/ginkgo"
	"github.com/onsi/gomega"
	"os"
	"strconv"
	"testing"
)

var (
	context        helpers.SuiteContext
	config         helpers.Config
	defaultTimeout time.Duration = 30 * time.Second
	cfPushTimeout  time.Duration = 5 * time.Minute
	statsdClient   *statsd.Client
	metricsPrefix  string
	loopCount      int
)

func TestBitsServicePerformanceTests(t *testing.T) {
	config = helpers.LoadConfig()

	if config.DefaultTimeout > 0 {
		defaultTimeout = config.DefaultTimeout * time.Second
	}

	if config.CfPushTimeout > 0 {
		cfPushTimeout = config.CfPushTimeout * time.Second
	}

	metricsPrefix = os.Getenv("PERFORMANCE_TEST_METRICS_PREFIX")

	if metricsPrefix != "" {
		metricsPrefix += "."
	}
	fmt.Printf("Using metricsPrefix=%v", metricsPrefix)

	loopCount = loopCountFromEnv()
	fmt.Printf("Using loopCount=%v", loopCount)

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

	gomega.RegisterFailHandler(ginkgo.Fail)
	ginkgo.RunSpecs(t, "BitsServicePerformanceTests Suite")
}

func loopCountFromEnv() int {
	loopCountStr := os.Getenv("LOOP_COUNT")

	if loopCountStr == "" {
		return 1
	} else {
		loopCount, err := strconv.Atoi(loopCountStr)

		if err != nil {
			panic(err)
		}

		return loopCount
	}
}
