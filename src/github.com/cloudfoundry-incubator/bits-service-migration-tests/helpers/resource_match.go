package helpers

import (
	"crypto/sha1"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"math"
	"os"
	"path"

	. "github.com/onsi/gomega"
)

func ResourceMatchBody(appDirectory string) []byte {
	files, err := ioutil.ReadDir(appDirectory)
	Expect(err).ToNot(HaveOccurred())

	resources := appResources{}
	for _, file := range files {
		sha1 := sha1ForFile(path.Join(appDirectory, file.Name()))

		resources = append(resources, appResource{
			Sha1: sha1,
			Size: file.Size(),
		})
	}

	body, err := json.Marshal(resources)
	Expect(err).ToNot(HaveOccurred())

	return body
}

type appResources []appResource

type appResource struct {
	Sha1 string `json:"sha1"`
	Size int64  `json:"size"`
}

const filechunk = 8192

func sha1ForFile(filepath string) string {
	hash := sha1.New()
	file, err := os.Open(filepath)
	defer file.Close()

	info, err := file.Stat()
	Expect(err).ToNot(HaveOccurred())

	filesize := info.Size()
	blocks := uint64(math.Ceil(float64(filesize) / float64(filechunk)))

	for i := uint64(0); i < blocks; i++ {
		blocksize := int(math.Min(filechunk, float64(filesize-int64(i*filechunk))))
		buf := make([]byte, blocksize)
		file.Read(buf)
		io.WriteString(hash, string(buf))
	}

	return fmt.Sprintf("%x", hash.Sum(nil))
}
