module xmbfile;

import std.stdio;
import std.stream;

//!
align(1) struct XMBHeader
{
	char[2]	magic; //X1
	uint	size; // data length
	char[2]	rootmagic; // XR
	uint	uk1; // = 4
	uint	uk2; // Format: 7=AoM 8=AoE
}

// Convenient storage for the internal tree
struct XMLAttribute
{
	wstring name;
	wstring value;
}

//!
struct XMLElement
{
	wstring			name;
	int				linenum;
	wstring			text;
	XMLElement*[]	childs; // Array of pointers to XMLElement
	XMLAttribute[]	attrs;
}

//! Enforces initialisation/termination the XML system
class XMLReader
{
	this()
	{
//		XMLPlatformUtils::Initialize();
	}

	XMBFile* LoadFromXML();
}

class XMBFile
{
private:
	XMLElement* root;
	std.stream.File file;
//	enum { UNKNOWN, AOM, AOE3 } format;

/*
	void DeallocateElement(XMLElement* el)
	{
		size_t i;

		for (i = 0; i < (*el).childs.length; ++i)
			DeallocateElement(el->childs[i]);

		delete el;
	}
*/

	// Read AoE style strings
	wstring ReadString()
	{
		assert(file !is null);
		uint namelen;
		file.read(namelen);
		ubyte[] buffer;
		file.readExact(buffer.ptr, namelen);
		return cast(wstring) buffer[0 .. namelen-1];
	}

	XMLElement* ParseNode(wstring[] ElementNames, wstring[] AttributeNames)
	{
		char[2] header;
		file.readExact(header.ptr, 2);
		assert(header == "XN");
		uint length;
		file.read(length);

		XMLElement* node = new XMLElement;

		(*node).text = ReadString();

		uint nameid;
		file.read(nameid);
		(*node).name = ElementNames[nameid];

//		if (file->format == XMBFile::AOE3)
//		{
			uint linenum;
			file.read(linenum);
			(*node).linenum = linenum;
//		}

		uint NumAttributes;
		file.read(NumAttributes);
//		node->attrs.reserve(NumAttributes);
		for (uint i = 0; i < NumAttributes; ++i)
		{
			uint AttrID;
			file.read(AttrID);

			XMLAttribute attr;
			attr.name = AttributeNames[AttrID];
			attr.value = ReadString();
			(*node).attrs[i]=attr;
		}

		uint NumChildren;
		file.read(NumChildren);
//		node->childs.reserve(NumChildren);
		for (uint i = 0; i < NumChildren; ++i)
		{
			XMLElement* child = ParseNode(ElementNames, AttributeNames);
			if (!child)
			{
				// TODO: gefährlich!
				//DeallocateElement(node);
				return null;
			}
			(*node).childs[i]=child;
		}

		return node;
	}

public:
	this()
	{
		root = null;
	}
/*	~this()
	{
		DeallocateElement(root);
	}
*/
	// This does *not* understand l33t-compressed data. Please
	// decompress them first.
	void LoadFromXMB(string filename)
	{
		XMBHeader header;
		file = new std.stream.File();
		try
		{
			file.readExact(&header, header.sizeof);
			assert(header.magic == "X1");
			assert(header.rootmagic == "XR");
			assert(header.uk1 == 4);
			//
			
			wstring[] ElementNames;
			uint	NumElements;
			file.read(NumElements);
			for(uint i=0; i<NumElements; i++)
			{
				ElementNames[i] = ReadString();
			}

			wstring[] AttributeNames;
			uint	NumAttributes;
			file.read(NumAttributes);
			for(uint i=0; i<NumAttributes; i++)
			{
				AttributeNames[i] = ReadString();
			}

				root = ParseNode(ElementNames, AttributeNames);
		}
		catch(Exception e)
		{
			writef("%.*s\n", e.toString());
		}
		finally
		{
			file.close();
		}
	}

	// Caller should convert the returned data to some encoding, and
	// prepend "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" (or whatever
	// is appropriate for that encoding)
	wstring SaveAsXML();

	void SaveAsXMB();
}