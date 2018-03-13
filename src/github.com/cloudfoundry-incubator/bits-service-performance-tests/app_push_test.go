package main_test

import (
	"strings"

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

			appName := generator.PrefixedRandomName("APP")
			Expect(
				cf.Cf("push", appName, "-p", "assets/golang", "-b", "go_buildpack").Wait(cfPushTimeout)).
				To(Exit(0))

			metricsService.SendTimingMetric(asSparseMetric("cf-push"), time.Since(startTime))

			Expect(
				cf.Cf("delete", appName, "-f").Wait(cfPushTimeout)).
				To(Exit(0))
		}

		Expect(metricsService.filename).To(BeAnExistingFile())

		lastLine, err := lastLine(metricsService.filename)
		Expect(err).NotTo(HaveOccurred())

		parts := strings.Split(lastLine, ",")
		Expect(parts).To(HaveLen(4))

		_, err = time.Parse(time.RFC3339, parts[0])
		Expect(err).NotTo(HaveOccurred())

		Expect(parts[1]).To(Equal("cf-push_sparse-avg"))
		Expect(parts[2]).To(MatchRegexp("\\d+"))
		Expect(parts[3]).To(MatchRegexp("ms"))
	})
})

func asSparseMetric(metricName string) string {
	return metricsPrefix + metricName + "_sparse-avg"
}
