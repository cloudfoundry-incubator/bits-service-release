package main_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"

	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
)

var _ = Describe("Pushing an app", func() {
	It("stops the time for pushing an app", func() {
		for index := 0; index < loopCount; index++ {
			startTime := time.Now()

			push := "push"
			if shouldUseV3Push {
				push = "v3-push"
			}

			appName := generator.PrefixedRandomName("APP")
			Expect(
				cf.Cf(push, appName, "-p", "assets/golang", "-b", "go_buildpack").Wait(cfPushTimeout)).
				To(Exit(0))

			metricsService.SendTimingMetric(asSparseMetric("cf-"+push), time.Since(startTime))

			Expect(
				cf.Cf("delete", appName, "-f").Wait(cfPushTimeout)).
				To(Exit(0))
		}
	})
})

func asSparseMetric(metricName string) string {
	return metricsPrefix + metricName + "_sparse-avg"
}
