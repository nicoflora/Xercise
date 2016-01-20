
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
Parse.Cloud.define("hello", function(request, response) {
  response.success("Hello world!");
});

Parse.Cloud.define("hello2", function(request, response) {
  response.success("Hello world2!");
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
				response("Error");
			}
    	});
    //}
});