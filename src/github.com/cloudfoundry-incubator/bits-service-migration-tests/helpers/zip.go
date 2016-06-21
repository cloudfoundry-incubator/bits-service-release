package helpers

import (
	"archive/zip"
	"io"
	"os"
	"path"

	. "github.com/onsi/gomega"
)

func Unzip(sourceFilePath, destinationPath string) {
	reader, err := zip.OpenReader(sourceFilePath)
	Expect(err).ToNot(HaveOccurred())
	defer reader.Close()

	for _, file := range reader.File {
		rc, err := file.Open()
		defer rc.Close()
		Expect(err).ToNot(HaveOccurred())

		outputFile, err := os.Create(path.Join(destinationPath, file.Name))
		defer outputFile.Close()
		_, err = io.Copy(outputFile, rc)
		Expect(err).ToNot(HaveOccurred())
	}
}
