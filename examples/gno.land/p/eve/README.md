WIP
--- 

What's left to get to 'final' version of eve framework

### requirements

A user can publish an item as a revision or update where the old CID is replaced with a new one.
Old cid can be removed or kept as a reference.

Gno.land visitors choose to view older revisions. (by traversing parent links)

Other gno realms may embed path to /r/eve/home/?cid=... to show specific revisions.

Page view has common footer menu that links to metadata and version info.


As a user I can see the Object Registry (index at /r/lab/home?glyph=OfficeHours)
Each registered object links out to its own realm (officehours at /r/labs/OfficeHours)

Users can update the preferred view of an object if they are the original author.

FUTURE: without using cur realm (realm crossing) - we can still build an immutable oracle.
This is an append only fashion that does not allow permissions, only that each new object has a unique CID

The Event Stream of (Glyph, URL, CID) is an immutable log of all objects ever created.

### Metadata

A design principle from gno.land: A realm SHOULD always resemble gno.land/r/ view.
i.e. a fork on another realm should ideally use same markdown renderer and support same metadata.

The metadata for each page SHOULD be linked from each eve.PageTemplate view.

Every object is required to have a CID, JsonLD{ name, description }, and committer/author.
Every object MAY have additional metadata such as tags, categories, license, etc.

### Versioning

Every object may have a link to the previous version.
An object MAY have multiple parents (merging branches).

### QueryParameters as Serializable State

A Projectable Object accepts path as a 'Probe' to determine what to render.
A Probe is a 'path' that is serializable state that can be shared via URL query parameters.

A complete view of an object is only inspectable by probing the inner dimensions of the object.
This means that a user can share a link to a specific view of an object. 

### Identity and Types

Objects have metadata in the shape of JsonLD.
Each Object is identified by its CID.

Unless specified otherwise, an object is assumed to be of type "Thing" (schema.org/Thing).
An object MAY have multiple types (schema.org allows this).

## Existing Projectable Objects

### eve.Flyer Object
A Flyer is a Projectable Object that has a title, description, image, and link.

### Event Projectable Object
"Event" (schema.org/Event).
An Event object has properties such as startDate, endDate, location, performer, etc.

### Calendar Event Projectable Object
A Calendar Event is a Projectable Object that can render different views based on the Probe.

### Office Hours Event
A specialized event formatted as ICS, contains a recurrence rule (RRULE).

### Probes

The Render() function accepts a Probe that is a path that is serializable state that can be shared via URL query parameters.

Object + Probe => RenderedView

### Future Work
- Permissions and Access Control Lists (ACLs) 
- Standard views of common object types (e.g., Articles, Projects, Profiles)
