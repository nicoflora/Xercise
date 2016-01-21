
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
Parse.Cloud.define("hello", function(request, response) {
  response.success("Hello world!");
});

// Need Type(e.g. "Exercise"), id, and rating(e.g. "thumbs_Up_Rate")
Parse.Cloud.define("rate", function(request, response) {
    //var Test = Parse.Object.extend(request.params.type);
    var query = new Parse.Query(request.params.type);
    query.equalTo("identifier", request.params.id);
    query.first({
        success: function(object) {
            object.increment(request.params.rating);
            object.save(null, {
                success:function() {
                    response.success("Success");
                },
                error:function(error) { 
                    console.log('Error saving incremented value');
                    console.log(error);
                    response.error("Error");
                }
            });
        }, error: function (error) { 
            console.log('Error finding an exercise with the input data');
            console.log(error);
            response("Error");
        }
    });
});

// Need request.params.muscleGroup
Parse.Cloud.define("getExercise", function(request, response) {
    //if request.params.muscleGroup != "" {
		var countQuery = new Parse.Query("Exercise");
		countQuery.equalTo("muscle_group", request.params.muscleGroup);
		countQuery.count({
			success: function(count) {
				var randomNumber = Math.floor(Math.random() * count);
				console.log("Random number = " + randomNumber)
				var query = new Parse.Query("Exercise");
				query.equalTo("muscle_group", request.params.muscleGroup);
				query.skip(randomNumber)
				query.first({
					success: function(object) {
						var responseArray = new Array();
						responseArray.push(object.get("name"));
						responseArray.push(object.get("identifier"));
						responseArray.push(object.get("muscle_group"));
						responseArray.push(object.get("exercise_desc"));
						responseArray.push(object.get("image").url());
						response.success(responseArray);						
					}, error: function (error) { 
						console.log('Error finding an exercise');
						console.log(error);
						response.error("Error getting an exercise");
					}	
				});
			}, error: function (error) { 
				console.log('Error finding an exercise with the input data');
				console.log(error);
				response.error("Error");
			}
    	});
    //}
});

// Need request.params.muscleGroup
Parse.Cloud.define("getWorkout", function(request, response) {
	var countQuery = new Parse.Query("Workout");
		countQuery.equalTo("muscle_group", request.params.muscleGroup);
		countQuery.count({
			success: function(count) {
				var randomNumber = Math.floor(Math.random() * count);
				var query = new Parse.Query("Workout");
				query.equalTo("muscle_group", request.params.muscleGroup);
				query.skip(randomNumber);
				query.first({
					success: function(object) {
						var jsonResults = new Array();
						var ids = object.get("exercise_ids");
						var names = object.get("exercise_names");
						//if (ids.count > 0 && names.count > 0) {
							jsonResults["ids"] = ids;
							jsonResults["names"] = names;
							var result = {ids : ids, names: names};
							response.success(object);
						/*} else {
							console.log('No ids or names');
							response.error("This workout contains no exercises");
						}*/
					}, error: function (error) { 
						console.log('Error finding a workout');
						console.log(error);
						response.error("Error getting a random workout");
					}	
				});
			}, error: function (error) { 
				console.log('Error counting the workouts');
				console.log(error);
				response.error("Error searching the workouts");
			}
		});
});