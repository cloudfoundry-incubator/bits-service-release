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
	context         helpers.SuiteContext
	config          helpers.Config
	defaultTimeout  time.Duration = 30 * time.Second
	cfPushTimeout   time.Duration = 5 * time.Minute
	metricsService  *CombinedStatsdAndLocalFileEmittingMetricsService
	metricsPrefix   string
	loopCount       int
	shouldUseV3Push bool
)

type CombinedStatsdAndLocalFileEmittingMetricsService struct {
	filename     string
	statsdClient *statsd.Client
}

func (ms *CombinedStatsdAndLocalFileEmittingMetricsService) SendTimingMetric(name string, duration time.Duration) {
	milliseconds := duration.Seconds() * 1000
	ms.statsdClient.Timing(name, milliseconds)
	file, e := os.OpenFile(ms.filename, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if e != nil {
		panic(e)
	}
	defer file.Close()
	fmt.Fprintf(file, "%v,%v,%d,ms\n", time.Now().UTC().Format(time.RFC3339), name, int(milliseconds))
}

func (ms *CombinedStatsdAndLocalFileEmittingMetricsService) Close() {
	ms.statsdClient.Close()
}

func TestBitsServicePerformanceTests(t *testing.T) {
	config = helpers.LoadConfig()

	if config.DefaultTimeout > 0 {
		defaultTimeout = config.DefaultTimeout * time.Second
	}

	if config.CfPushTimeout > 0 {
		cfPushTimeout = config.CfPushTimeout * time.Second
	}

	if os.Getenv("PERFORMANCE_TEST_SHOULD_USE_V3_PUSH)") {
		shouldUseV3Push = true
	}

	metricsPrefix = os.Getenv("PERFORMANCE_TEST_METRICS_PREFIX")

	if metricsPrefix != "" {
		metricsPrefix += "_"
	}
	fmt.Printf("Using metricsPrefix=%v", metricsPrefix)

	loopCount = loopCountFromEnv()
	fmt.Printf("Using loopCount=%v", loopCount)

	context = helpers.NewContext(config)
	environment := helpers.NewEnvironment(context)

	BeforeSuite(func() {
		environment.Setup()

		statsdClient, e := statsd.New() // Connect to the UDP port 8125 by default.
		Expect(e).NotTo(HaveOccurred())
		metricsService = &CombinedStatsdAndLocalFileEmittingMetricsService{
			filename:     os.Getenv("PERFORMANCE_TEST_METRICS_CSV_FILE"),
			statsdClient: statsdClient,
		}
	})

	AfterSuite(func() {
		metricsService.Close()
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
