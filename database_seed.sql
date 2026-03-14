-- SQL script to set up the learning_resources table and insert the sample data provided.
-- Run this in your Supabase SQL Editor.

-- 1. Create the learning_resources table if it doesn't exist
CREATE TABLE IF NOT EXISTS learning_resources (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    learning_path_id BIGINT REFERENCES learning_paths(id) ON DELETE CASCADE,
    resource_type TEXT NOT NULL,
    platform TEXT NOT NULL,
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    duration TEXT,
    rating DECIMAL(3,2),
    free BOOLEAN DEFAULT TRUE,
    certificate BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Insert the sample data (Assumes learning_path_id = 1 exists)
-- If learning_path_id 1 doesn't exist, this will fail or need a valid ID.
INSERT INTO learning_resources (learning_path_id, resource_type, platform, title, url, duration, rating, free, certificate)
VALUES 
(1, 'course', 'Coursera', 'Software Engineering Basics', 'https://www.coursera.org/learn/software-engineering', '20 hours', 4.7, true, true),
(1, 'course', 'Udemy', 'Complete Software Engineer Bootcamp', 'https://www.udemy.com/course/software-engineer/', '40 hours', 4.6, false, true),
(1, 'course', 'edX', 'CS50 Introduction to Computer Science', 'https://www.edx.org/course/introduction-computer-science-harvardx-cs50x', '12 weeks', 4.9, true, true),
(1, 'course', 'freeCodeCamp', 'Scientific Computing with Python', 'https://www.freecodecamp.org/learn/scientific-computing-with-python/', '300 hours', 4.8, true, true)
ON CONFLICT (id) DO NOTHING;
