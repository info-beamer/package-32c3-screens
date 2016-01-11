# defusedxml
#
# Copyright (c) 2013 by Christian Heimes <christian@python.org>
# Licensed to PSF under a Contributor Agreement.
# See http://www.python.org/psf/license for licensing details.
"""Defused xml.etree.ElementTree facade
"""
from __future__ import print_function, absolute_import

from xml.etree.ElementTree import XMLParser as _XMLParser
from xml.etree.ElementTree import iterparse as _iterparse
_IterParseIterator = None
from xml.etree.ElementTree import TreeBuilder as _TreeBuilder
from xml.etree.ElementTree import parse as _parse

from .common import (DTDForbidden, EntitiesForbidden,
                     ExternalReferenceForbidden, _generate_etree_functions)

__origin__ = "xml.etree.ElementTree"

class DefusedXMLParser(_XMLParser):
    def __init__(self, html=0, target=None, encoding=None,
                 forbid_dtd=False, forbid_entities=True,
                 forbid_external=True):
        # Python 2.x old style class
        _XMLParser.__init__(self, html, target, encoding)
        self.forbid_dtd = forbid_dtd
        self.forbid_entities = forbid_entities
        self.forbid_external = forbid_external
        parser = self._parser
        if self.forbid_dtd:
            parser.StartDoctypeDeclHandler = self.defused_start_doctype_decl
        if self.forbid_entities:
            parser.EntityDeclHandler = self.defused_entity_decl
            parser.UnparsedEntityDeclHandler = self.defused_unparsed_entity_decl
        if self.forbid_external:
            parser.ExternalEntityRefHandler = self.defused_external_entity_ref_handler

    def defused_start_doctype_decl(self, name, sysid, pubid,
                                   has_internal_subset):
        raise DTDForbidden(name, sysid, pubid)

    def defused_entity_decl(self, name, is_parameter_entity, value, base,
                            sysid, pubid, notation_name):
        raise EntitiesForbidden(name, value, base, sysid, pubid, notation_name)

    def defused_unparsed_entity_decl(self, name, base, sysid, pubid,
                                     notation_name):
        # expat 1.2
        raise EntitiesForbidden(name, None, base, sysid, pubid, notation_name)

    def defused_external_entity_ref_handler(self, context, base, sysid,
                                            pubid):
        raise ExternalReferenceForbidden(context, base, sysid, pubid)


# aliases
XMLTreeBuilder = XMLParse = DefusedXMLParser

parse, iterparse, fromstring = _generate_etree_functions(DefusedXMLParser,
        _TreeBuilder, _IterParseIterator, _parse, _iterparse)
XML = fromstring
