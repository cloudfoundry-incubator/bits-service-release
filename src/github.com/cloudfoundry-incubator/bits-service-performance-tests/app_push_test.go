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

			appName := generator.PrefixedRandomName("APP")
			Expect(
				cf.Cf("push", appName, "-p", "assets/dora").Wait(cfPushTimeout)).
				To(Exit(0))

			statsdClient.Timing(metricsPrefix+"cf-push", time.Since(startTime).Seconds()*1000)
		}
	})
})
