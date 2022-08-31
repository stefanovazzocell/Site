+++
title = "CompressionStream JS API"
slug = "compression_stream_api"
date = 2023-08-04
description = "Discovering JavaScript's CompressionStream API"
+++

I recently came across the `CompressionStream` JavaScript API to allow me to seamlessly compress data on a browser.

<!-- more -->

## Discovery

I was working on a personal project where I had to upload a large CSV file to a server in Go for processing via a web UI. The challenge here was that the CSV file could be larger than 100MB which, given that I use the free tier of Cloudflare would not have been possible.

Initially, I considered some options such as requiring the CSV file to be compressed beforehand but that was a bad UX.
But eventually I came across the [CompressionStream API](https://developer.mozilla.org/en-US/docs/Web/API/CompressionStream) and the [Stream API](https://developer.mozilla.org/en-US/docs/Web/API/Streams_API); the former having an 80+% adoption globally and being supported by all major browsers according to [caniuse.com](https://caniuse.com/mdn-api_compressionstream).

Thanks to CompressionStream I am able to natively compress a file on the user's browser, upload it to the backend where in Go I could extract it and read the CSV entries on demand for processing and also send back a compressed reply to the user's browser which can be decompressed again and presented to the user as a downloadable file.

## Code sample

The following JavaScript code demonstrates how to leverage CompressionStream to compress a file on the user's browser, upload it to a backend server, and handle the response for processing and downloading.

```javascript
// Read a file picked by the user, compress it, and turn it into a Blob.
const file = document.getElementById("fileInput").files[0];
const compressStream = file.stream().pipeThrough(new CompressionStream("gzip"));
const blob = await new Response(compressStream).blob();
// Upload data
const response = await fetch("/api/upload", {
    method: "POST",
    body: blob,
})
if (response.status != 200) {
    // TODO: Handle error
    return
}
// Write the response to a Blob while decompressing it.
const decompressStream = response.body.pipeThrough(new DecompressionStream("gzip"))
const resultBlob = await new Response(decompressStream).blob();
// Provide a download link
document.getElementById("downloadLink").download = "file.csv"
document.getElementById("downloadLink").href = window.URL.createObjectURL(resultBlob);
```

Unfortunately, it's not yet possible to provide a ReadableStream to fetch as the request body (which would be more resource efficient compared to creating a Blob) as it is still an experimental API feature. You can find an example of this in [Chrome's blog](https://developer.chrome.com/articles/fetch-streaming-requests/) if you're interested to find out how it might work in the future.

On the server side I have the following Go code template that handles the API endpoint to stream the compressed CSV data and writes the response.

```go
func handler(w http.ResponseWriter, r *http.Request) {
	// GZIP Reader
	gzipReader, err := gzip.NewReader(r.Body)
	if err != nil {
		log.Printf("failed to create gzipReader, err: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	// CSV Reader
	csvReader := csv.NewReader(gzipReader)
	// Prepare to write response
	responseBuffer := bytes.Buffer{}
	gzipWriter, err := gzip.NewWriterLevel(&responseBuffer, gzip.BestCompression)
	if err != nil {
		log.Printf("failed to create gzip writer: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	csvWriter := csv.NewWriter(gzipWriter)
	// Process entries
	for {
		// Read row
		record, err := csvReader.Read()
		if err == io.EOF {
			break
		} else err != nil {
			log.Print(err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		// TODO: Process entry, optionally write to csvWriter
	}
	// Close writers and submit response
	err = gzipReader.Close()
	if err != nil {
		log.Printf("error while closing gzipReader: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	csvWriter.Flush()
	err = gzipWriter.Close()
	if err != nil {
		log.Printf("error while closing gzipWriter: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	_, err = w.Write(responseBuffer.Bytes())
	if err != nil {
		log.Printf("error while writing response: %v", err)
	}
}
```

## Conclusions

This approach can be beneficial for enabling users to upload potentially large files from a website, especially when bandwidth or upload size are of concern.

I'm hoping that support for [ReadableStream in fetch requests body](https://caniuse.com/mdn-api_request_request_request_body_readablestream) improves soon, especially with Safari and Firefox.

Perhaps it's time for me to revisit my [Rocket](https://rkt.one/) personal project, but that's for another blog post.