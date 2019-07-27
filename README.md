
# Custom wrapper for XMLParser in order to handle writing, reading and updating XMP-sidecar files.

This wrapper allows you to read, write and update xmp-items stored as attributes 'rdf:Description' and stored as nested dc-elements. When updating a xmp-file this wrapper removes the old file and generates new XML to store at the same location. By doing so, this wrapper regenerates all elements of the old file including updated xmp-items. This seems to be rather unique in the world of applications that edit XMP.

This class is part of [Pictureflow](https://pictureflow.app).

**important note**: To make the tests succeed, your app should not be sandboxed.
