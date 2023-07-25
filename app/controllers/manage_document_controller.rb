# Copyright 2012 Trustees of FreeBMD
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#
class ManageDocumentController < ApplicationController
	def freecen_handbook
		if Refinery::Page.where(slug: 'freecen-handbook').exists?
			@page = Refinery::Page.where(slug: 'freecen-handbook').first.parts.first.body.html_safe
			@title = Refinery::Page.where(slug: 'freecen-handbook').first.title.html_safe
		end
		render 'handbook'
	end
end