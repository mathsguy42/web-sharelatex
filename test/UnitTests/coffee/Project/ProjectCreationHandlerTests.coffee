spies = require('chai-spies')
chai = require('chai').use(spies)
sinon = require("sinon")
should = chai.should()
modulePath = "../../../../app/js/Features/Project/ProjectCreationHandler.js"
SandboxedModule = require('sandboxed-module')
Settings = require('settings-sharelatex')
Path = require "path"
_ = require("underscore")

describe 'ProjectCreationHandler', ->
	ownerId = '4eecb1c1bffa66588e0000a1'
	projectName = 'project name goes here'
	project_id = "4eecaffcbffa66588e000008"
	docId = '4eecb17ebffa66588e00003f'
	rootFolderId = "234adfa3r2afe"

	beforeEach ->
		@ProjectModel = class Project
			constructor:(options = {})->
				@._id = project_id
				@owner_ref = options.owner_ref
				@name = options.name
			save: sinon.stub().callsArg(0)
			rootFolder:[{
				_id: rootFolderId
				docs: []
			}]
		@FolderModel = class Folder
			constructor:(options)->
				{@name} = options
		@ProjectEntityHandler =
			addDoc: sinon.stub().callsArgWith(4, null, {_id: docId})
			addFile: sinon.stub().callsArg(4)
			setRootDoc: sinon.stub().callsArg(2)

		@user = 
			first_name:"first name here"
			last_name:"last name here"
			ace: 
				spellCheckLanguage:"de"

		@User = findById:sinon.stub().callsArgWith(2, null, @user)
		@callback = sinon.stub()
		@handler = SandboxedModule.require modulePath, requires:
			'../../models/User': User:@User
			'../../models/Project':{Project:@ProjectModel}
			'../../models/Folder':{Folder:@FolderModel}
			'./ProjectEntityHandler':@ProjectEntityHandler
			'logger-sharelatex': {log:->}

	describe 'Creating a Blank project', ->
		beforeEach ->
			@ProjectModel::save = sinon.stub().callsArg(0)

		describe "successfully", ->

			it "should save the project", (done)->
				@handler.createBlankProject ownerId, projectName, =>
					@ProjectModel::save.called.should.equal true
					done()
				
			it "should return the project in the callback", (done)->
				@handler.createBlankProject ownerId, projectName, (err, project)->
					project.name.should.equal projectName
					(project.owner_ref + "").should.equal ownerId
					done()

			it "should set the language from the user", (done)->
				@handler.createBlankProject ownerId, projectName, (err, project)->
					project.spellCheckLanguage.should.equal "de"
					done()

		describe "with an error", ->
			beforeEach ->
				@ProjectModel::save = sinon.stub().callsArgWith(0, new Error("something went wrong"))
				@handler.createBlankProject ownerId, projectName, @callback
			
			it 'should return the error to the callback', ->
				should.exist @callback.args[0][0]

	describe 'Creating a python project', ->
		beforeEach ->
			@project = new @ProjectModel()
			@handler._buildTemplate = (template_name, user, project_name, callback) ->
				if template_name == "main.py"
					return callback(null, ["main.py", "lines"])
				throw new Error("unknown template: #{template_name}")
			sinon.spy @handler, "_buildTemplate"
			@handler.createBlankProject = sinon.stub().callsArgWith(2, null, @project)
			@handler.createPythonProject(ownerId, projectName, @callback)

		it "should create a blank project first", ->
			@handler.createBlankProject.calledWith(ownerId, projectName)
				.should.equal true

		it 'should insert main.tex', ->
			@ProjectEntityHandler.addDoc.calledWith(project_id, rootFolderId, "main.py", ["main.py", "lines"])
				.should.equal true

		it 'should set the main doc id', ->
			@ProjectEntityHandler.setRootDoc.calledWith(project_id, docId).should.equal true

		it 'should build the main.py template', ->
			@handler._buildTemplate
				.calledWith("main.py", ownerId, projectName)
				.should.equal true

	describe 'Creating an R project', ->
		beforeEach ->
			@project = new @ProjectModel()
			@handler._buildTemplate = (template_name, user, project_name, callback) ->
				if template_name == "main.R"
					return callback(null, ["main.R", "lines"])
				throw new Error("unknown template: #{template_name}")
			sinon.spy @handler, "_buildTemplate"
			@handler.createBlankProject = sinon.stub().callsArgWith(2, null, @project)
			@handler.createRProject(ownerId, projectName, @callback)

		it "should create a blank project first", ->
			@handler.createBlankProject.calledWith(ownerId, projectName)
				.should.equal true

		it 'should insert main.tex', ->
			@ProjectEntityHandler.addDoc.calledWith(project_id, rootFolderId, "main.R", ["main.R", "lines"])
				.should.equal true

		it 'should set the main doc id', ->
			@ProjectEntityHandler.setRootDoc.calledWith(project_id, docId).should.equal true

		it 'should build the main.R template', ->
			@handler._buildTemplate
				.calledWith("main.R", ownerId, projectName)
				.should.equal true

