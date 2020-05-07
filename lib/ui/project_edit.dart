import 'package:flutter/material.dart';
import 'package:open_director/service_locator.dart';
import 'package:open_director/service/project_service.dart';
import 'package:open_director/model/project.dart';
import 'package:open_director/ui/director.dart';

class ProjectEdit extends StatelessWidget {
  final projectService = locator.get<ProjectService>();

  ProjectEdit(Project project) {
    if (project == null) {
      projectService.project = projectService.createNew();
    } else {
      projectService.project = project;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            (projectService.project.id == null) ? 'New video' : 'Edit title'),
      ),
      body: _ProjectEditForm(),
      resizeToAvoidBottomInset: true,
    );
  }
}

class _ProjectEditForm extends StatelessWidget {
  final projectService = locator.get<ProjectService>();
  // Neccesary static
  // https://github.com/flutter/flutter/issues/20042
  static final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width * 0.08,
            MediaQuery.of(context).size.height * 0.05,
            MediaQuery.of(context).size.width * 0.08,
            MediaQuery.of(context).size.height * 0.5,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  initialValue: projectService.project.title,
                  maxLength: 75,
                  onSaved: (value) {
                    projectService.project.title = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter a title for your video project',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                Padding(padding: EdgeInsets.only(top: 10)),
                TextFormField(
                  initialValue: projectService.project.description,
                  maxLines: 3,
                  maxLength: 1000,
                  onSaved: (value) {
                    projectService.project.description = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                Padding(padding: EdgeInsets.only(top: 10)),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: <
                    Widget>[
                  FlatButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                  RaisedButton(
                    child: Text('OK'),
                    onPressed: () async {
                      // If the form is valid
                      if (_formKey.currentState.validate()) {
                        // To call onSave in TextFields
                        _formKey.currentState.save();

                        // To hide soft keyboard
                        FocusScope.of(context).requestFocus(new FocusNode());

                        if (projectService.project.id == null) {
                          await projectService.insert(projectService.project);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    DirectorScreen(projectService.project)),
                          );
                        } else {
                          await projectService.update(projectService.project);
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
      onTap: () {
        // To hide soft keyboard
        FocusScope.of(context).requestFocus(new FocusNode());
      },
    );
  }
}
