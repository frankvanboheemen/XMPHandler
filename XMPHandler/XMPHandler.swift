//
//  XMPHandler.swift
//  XMPHandler
//
//  Created by Frank van Boheemen on 18/07/2019.
//  Copyright © 2019 Frank van Boheemen. All rights reserved.
//

import Foundation

enum XMPHandlerError: Swift.Error {
    case failedToParseXMP(url: URL, message: String)
    case invalidXMP(url: URL, message: String)
}

class XMPHandler: NSObject, XMLParserDelegate {
    private var tempStack = [ParsedXMPElement]()
    private var parsedXMP : ParsedXMPElement?
    
    private let desiredDCObjectKeys = ["dc:title", "dc:description", "dc:rights"]
    
    func parseXMP(from file: URL) throws -> ([String : String]?) {
        let parser = XMLParser(contentsOf: file)
        parser?.delegate = self
        parser?.parse()
        
        guard let parsedXMP = parsedXMP else {
            throw XMPHandlerError.failedToParseXMP(url: file, message: "Failed to parse XMP from \(file.path).")
        }
        
        guard parsedXMP.name == "x:xmpmeta",
            let description = parsedXMP["rdf:RDF"]?["rdf:Description"] else {
                throw XMPHandlerError.invalidXMP(url: file, message: "Content of '\(file.path)' does not conform compatible XMP-format.")
        }
        
        var foundValues = description.attributes
        
        for key in desiredDCObjectKeys {
            if let string = description[key]?["rdf:Alt"]?["rdf:li"]?.text {
                foundValues[key] = string
            }
        }
        
        return foundValues
    }
    
    func saveXMP(xmpItems: [String: String], to location: URL) {
        var updatedXMPItems : [String : String]
        
        if FileManager.default.fileExists(atPath: location.path),
            let result = try? parseXMP(from: location) {
            updatedXMPItems = result
            
            for item in xmpItems {
                updatedXMPItems[item.key] = item.value
            }
        } else {
            updatedXMPItems = xmpItems
        }
        
        //Split all the values up into either attributes for the description-element or dcObjects, which should be saved differntly in the XML
        var attributes = [String: String]()
        var dcObjects = [String: String]()
        
        for item in updatedXMPItems {
            if item.key.prefix(upTo: item.key.index(item.key.startIndex, offsetBy: 2)) == "dc" {
                dcObjects[item.key] = item.value
            } else {
                attributes[item.key] = item.value
            }
        }
        
        let xmp : XMLElement
        
        if parsedXMP != nil {
            //Because the XMP could contain elements we are not explicitly looking for, updating xmp items needs to be done a bit more careful.
            updateParsedXMP(with: attributes, and: dcObjects)
            xmp = transform(parsedXMP: parsedXMP!)
        } else {
            xmp = createNewXMP(attributes: attributes, dcObjects: dcObjects)
        }
        
        let xml = XMLDocument(rootElement: xmp)
        let xmlData = xml.xmlData(options: [.nodePrettyPrint])
        try? xmlData.write(to: URL(fileURLWithPath: location.path))
        
    }
    
    //MARK: - Private methods
    
    private func updateParsedXMP(with updatedAttributes : [String: String], and updatedObjects: [String: String]) {
        if let parsedXMP = parsedXMP,
            let description = parsedXMP["rdf:RDF"]?["rdf:Description"] {
            description.attributes = updatedAttributes
            
            for object in updatedObjects {
                if let xmpObject = description[object.key]?["rdf:Alt"]?["rdf:li"] {
                    xmpObject.text = object.value
                } else {
                    description.childElements.append(createParsedXMPElement(for: object))
                }
            }
        }
    }
    
    private func createParsedXMPElement(for dcObject: (key: String, value: String)) -> ParsedXMPElement {
        /// Creates Parsed XMP element for a
        let liElement = ParsedXMPElement(name: "rdf:li")
        liElement.text = dcObject.value
        liElement.attributes = ["xml:lang" : "x-default"]
        
        let altElement = ParsedXMPElement(name: "rdf:Alt")
        altElement.childElements.append(liElement)
        
        let dcElement = ParsedXMPElement(name: dcObject.key)
        dcElement.childElements.append(altElement)
        
        return dcElement
    }
    
    private func transform(parsedXMP: ParsedXMPElement) -> XMLElement {
        var childElements = [XMLElement]()
        for child in parsedXMP.childElements {
            let element = transform(parsedXMP: child)
            childElements.append(element)
        }

        let element = createXMLElement(name: parsedXMP.name,
                                       attributes: parsedXMP.attributes,
                                       options: nil,
                                       text: parsedXMP.text)

        for child in childElements {
            element.addChild(child)
        }

        return element
    }
    
    private func createXMLElement(name: String, attributes: [String: String], options: XMLNode.Options?, text: String?) -> XMLElement {
        let element : XMLElement
        
        if let options = options  {
            element = XMLElement(kind: .element, options: options)
            element.name = name
        } else {
            element = XMLElement(name: name)
        }
        
        for attribute in attributes {
            let node = XMLNode(kind: .attribute)
            node.name = attribute.key
            node.objectValue = attribute.value
            element.addAttribute(node)
        }
        
        if let text = text {
            element.stringValue = text
        }
        
        return element
    }
    
    private func createNewXMP(attributes: [String: String], dcObjects: [String: String])  -> XMLElement {
        let xmpElement = createXMLElement(name: "x:xmpmeta",
                                          attributes: ["xmlns:x": "adobe:ns:meta/", "x:xmptk": "XMP Core 5.6.0"],
                                          options: .nodePreserveAttributeOrder,
                                          text: nil)
        
        let rdf = createXMLElement(name: "rdf:RDF",
                                   attributes: ["xmlns:rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#"],
                                   options: .nodePreserveAttributeOrder,
                                   text: nil)
        
        var discriptionAttributes = ["xmlns:xmp":"http://ns.adobe.com/xap/1.0/",
                                     "xmlns:pictureflow" : "https://ns.pictureflow.app/1.0/",
                                     "xmlns:dc" : "http://purl.org/dc/elements/1.1/"]
        
        for attribute in attributes {
            discriptionAttributes[attribute.key] = attribute.value
        }
        let discription = createXMLElement(name: "rdf:Description",
                                           attributes: discriptionAttributes,
                                           options: [.nodePreserveAttributeOrder],
                                           text: nil)
        
        for object in dcObjects {
            if object.value.count > 0 {
                let liELement = createXMLElement(name: "rdf:li",
                                                 attributes: ["xml:lang" : "x-default"],
                                                 options: nil,
                                                 text: object.value)
                
                let altElement = createXMLElement(name: "rdf:Alt",
                                                  attributes: [:],
                                                  options: nil,
                                                  text: nil)
                altElement.addChild(liELement)
                
                let objectElement = createXMLElement(name: object.key,
                                                     attributes: [:],
                                                     options: nil,
                                                     text:nil)
                objectElement.addChild(altElement)
                discription.addChild(objectElement)
            }
        }
        
        rdf.addChild(discription)
        xmpElement.addChild(rdf)
        
        return xmpElement
    }
    
    //MARK: XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        let element = ParsedXMPElement(name: elementName)
        element.attributes = attributeDict
        
        tempStack.last?.childElements.append(element)
        tempStack.append(element)
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        //TODO: find a better way of filtering values from nested XMLElements
        if !string.contains("\n") {
            tempStack.last?.text = string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "x:xmpmeta",
            let last = tempStack.last {
            parsedXMP = last
        }
        tempStack.removeLast()
    }
}

class ParsedXMPElement {
    let name: String
    var text: String?
    var attributes = [String: String]()
    var childElements = [ParsedXMPElement]()
    
    init(name: String) {
        self.name = name
    }
    
    subscript(key: String) -> ParsedXMPElement? {
        get {
            let filterdElements = childElements.filter { $0.name == key }
            if let first = filterdElements.first {
                return first
            } else {
                return nil
            }
        }
    }
}
